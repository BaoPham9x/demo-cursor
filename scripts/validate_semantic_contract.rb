#!/usr/bin/env ruby
# frozen_string_literal: true

require "yaml"
require "set"

ROOT = File.expand_path("..", __dir__)
SCHEMA_PATH = File.join(ROOT, "star-schema/models/marts/schema.yml")
BUSINESS_CONTEXT_PATH = File.join(ROOT, "business-context.md")
MARTS_DIR = File.join(ROOT, "star-schema/models/marts")
MODULE_KEYS = %w[identifier schema table label description dimensions metrics joinPaths].to_set
DIMENSION_KEYS = %w[column label description type].to_set
METRIC_KEYS = %w[
  identifier name description calculation time dimensions category owner_emails is_private
  is_unlisted time_grains time_resampling filters slices value distinct_on numerator
  denominator format sql_expression numerator_sql denominator_sql
].to_set
FILTER_KEYS = %w[schema table column operator expression].to_set
SLICE_KEYS = %w[name filter].to_set
JOIN_PATH_KEYS = %w[from to type].to_set
JOIN_PATH_TYPE_VALUES = %w[one-to-one one-to-many].to_set
SCHEMA_JOIN_TYPE_VALUES = %w[one-to-one one-to-many many-to-one].to_set
DIMENSION_TYPE_VALUES = %w[categorical country city h3-cell-index time].to_set
CALCULATION_VALUES = %w[sum count count-distinct ratio custom-value custom-ratio].to_set

@errors = []

def error(message)
  @errors << message
end

def load_yaml(path)
  YAML.load_file(path)
rescue Psych::SyntaxError => e
  error("#{relative(path)} does not parse as YAML: #{e.message}")
  nil
end

def relative(path)
  path.sub("#{ROOT}/", "")
end

def business_deny_list
  line = File.readlines(BUSINESS_CONTEXT_PATH).find { |entry| entry.include?("Sensitive data to exclude") }
  return Set.new unless line

  line.split(":", 2).last.to_s.split(",").map { |item| item.strip.downcase }.reject(&:empty?).to_set
end

def split_select_list(text)
  parts = []
  current = +""
  depth = 0
  quote = nil

  text.each_char do |char|
    if quote
      quote = nil if char == quote
    elsif ["'", '"', "`"].include?(char)
      quote = char
    elsif char == "("
      depth += 1
    elsif char == ")"
      depth -= 1 if depth.positive?
    elsif char == "," && depth.zero?
      parts << current
      current = +""
      next
    end

    current << char
  end

  parts << current
  parts
end

def output_column_from_expression(expression)
  expression = expression.strip.sub(/,\z/, "").strip
  return nil if expression.empty?

  if expression =~ /\bas\s+`?([A-Za-z_][A-Za-z0-9_]*)`?\s*\z/i
    Regexp.last_match(1)
  elsif expression =~ /\A(?:[A-Za-z_][A-Za-z0-9_]*\.)?`?([A-Za-z_][A-Za-z0-9_]*)`?\z/
    Regexp.last_match(1)
  end
end

def sql_output_columns(path)
  lines = File.readlines(path).map { |line| line.sub(/--.*$/, "") }
  select_index = lines.each_index.select { |index| lines[index] =~ /^\s*SELECT\b/i }.last
  return [] unless select_index

  select_lines = []
  index = select_index + 1
  while index < lines.length
    break if lines[index] =~ /^\s*FROM\b/i

    select_lines << lines[index]
    index += 1
  end

  split_select_list(select_lines.join("\n")).map do |expression|
    output_column_from_expression(expression)
  end.compact
end

def column_ref(ref)
  return nil unless ref.is_a?(String)

  match = ref.match(/\A([A-Za-z_][A-Za-z0-9_]*)\.([A-Za-z_][A-Za-z0-9_]*)\z/)
  match && [match[1], match[2]]
end

def check_extra_keys(hash, allowed, context)
  extra = hash.keys.map(&:to_s).to_set - allowed
  error("#{context} has unsupported keys: #{extra.to_a.sort.join(', ')}") unless extra.empty?
end

schema = load_yaml(SCHEMA_PATH)
exit 1 unless schema

deny_list = business_deny_list
models = schema.fetch("models", [])
models_by_name = models.to_h { |model| [model.fetch("name"), model] }
table_to_model_name = models.to_h do |model|
  table = model.dig("meta", "steep", "target_table") || model.fetch("name")
  [table, model.fetch("name")]
end
columns_by_model = models.to_h do |model|
  [model.fetch("name"), model.fetch("columns", []).map { |column| column.fetch("name") }]
end
column_meta_by_model = models.to_h do |model|
  [
    model.fetch("name"),
    model.fetch("columns", []).to_h { |column| [column.fetch("name"), column.fetch("meta", {})] }
  ]
end

metric_ids = Hash.new { |hash, key| hash[key] = [] }

models.each do |model|
  model_name = model.fetch("name")
  model_columns = columns_by_model.fetch(model_name)
  column_meta = column_meta_by_model.fetch(model_name)
  steep = model.dig("meta", "steep") || {}
  model.fetch("columns", []).each do |column|
    name = column.fetch("name")
    meta = column.fetch("meta", {})
    dim_type = meta["dimension_type"]
    sensitive = meta["sensitive"] || deny_list.include?(name.downcase)

    if sensitive && dim_type != "none"
      error("#{model_name}.#{name} is sensitive or denied but dimension_type is #{dim_type.inspect}")
    end
  end

  sql_path = File.join(MARTS_DIR, "#{model_name}.sql")
  if File.exist?(sql_path)
    sql_columns = sql_output_columns(sql_path)
    missing_from_sql = model_columns - sql_columns
    missing_from_schema = sql_columns - model_columns
    error("#{model_name} schema columns missing from SQL SELECT: #{missing_from_sql.join(', ')}") unless missing_from_sql.empty?
    error("#{model_name} SQL SELECT columns missing from schema.yml: #{missing_from_schema.join(', ')}") unless missing_from_schema.empty?
  end

  steep.fetch("join_paths", []).each do |join_path|
    from_column = join_path["from_column"]
    to_table = join_path["to_table"]
    to_column = join_path["to_column"]
    join_type = join_path["join_type"]
    target_model_name = table_to_model_name[to_table]

    error("#{model_name} join has unsupported source join_type #{join_type.inspect}") unless SCHEMA_JOIN_TYPE_VALUES.include?(join_type)
    error("#{model_name} join from_column #{from_column.inspect} does not exist") unless model_columns.include?(from_column)

    if target_model_name.nil?
      error("#{model_name} join target table #{to_table.inspect} is not a known mart table")
    elsif !columns_by_model.fetch(target_model_name).include?(to_column)
      error("#{model_name} join target #{to_table}.#{to_column} does not exist")
    end
  end

  examples_by_column = model.fetch("columns", []).to_h do |column|
    [column.fetch("name"), Array(column.dig("meta", "example_values")).map(&:to_s)]
  end

  steep.fetch("reference_metrics", []).each do |metric|
    metric_id = metric["identifier"]
    metric_ids[metric_id] << model_name if metric_id

    case metric["calculation"]
    when "sum"
      error("#{model_name}.#{metric_id} sum metric is missing value") unless metric["value"]
    when "count-distinct"
      error("#{model_name}.#{metric_id} count-distinct metric is missing distinct_on") unless metric["distinct_on"]
    when "custom-value"
      error("#{model_name}.#{metric_id} custom-value metric is missing sql_expression") unless metric["sql_expression"]
    when "custom-ratio"
      %w[numerator_sql denominator_sql format].each do |key|
        error("#{model_name}.#{metric_id} custom-ratio metric is missing #{key}") unless metric[key]
      end
    end

    filter = metric["filter"]
    next unless filter

    match = filter.match(/\A([A-Za-z_][A-Za-z0-9_]*)\s+(equals|in)\s+(.+)\z/)
    unless match
      error("#{model_name}.#{metric_id} filter is not parseable: #{filter.inspect}")
      next
    end

    column, operator, expression = match.captures
    values = operator == "in" ? expression.split(",") : [expression]
    allowed_values = examples_by_column.fetch(column, [])
    missing_values = values.reject { |value| allowed_values.include?(value) }
    unless missing_values.empty?
      error("#{model_name}.#{metric_id} filter values not in schema.yml example_values for #{column}: #{missing_values.join(', ')}")
    end
  end
end

metric_ids.each do |identifier, locations|
  error("reference metric identifier #{identifier.inspect} is duplicated in #{locations.join(', ')}") if locations.length > 1
end

def validate_yaml_collection(paths, label, table_to_model_name, columns_by_model, column_meta_by_model, deny_list)
  metric_ids = Hash.new { |hash, key| hash[key] = [] }

  paths.each do |path|
    document = load_yaml(path)
    next unless document

    unless document.keys == ["module"]
      error("#{relative(path)} must have exactly one root key: module")
      next
    end

    mod = document.fetch("module")
    check_extra_keys(mod, MODULE_KEYS, "#{relative(path)} module")

    table = mod["table"]
    model_name = table_to_model_name[table]
    unless model_name
      error("#{relative(path)} references unknown module table #{table.inspect}")
      next
    end

    model_columns = columns_by_model.fetch(model_name)
    column_meta = column_meta_by_model.fetch(model_name)
    local_dimensions = Set.new

    Array(mod["dimensions"]).each do |dimension|
      check_extra_keys(dimension, DIMENSION_KEYS, "#{relative(path)} dimension #{dimension['column']}")
      column = dimension["column"]
      local_dimensions << column if column
      error("#{relative(path)} dimension #{column.inspect} does not exist on #{table}") unless model_columns.include?(column)
      error("#{relative(path)} dimension #{column.inspect} has unsupported type #{dimension['type'].inspect}") unless DIMENSION_TYPE_VALUES.include?(dimension["type"])

      meta = column_meta.fetch(column, {})
      if meta["sensitive"] || deny_list.include?(column.to_s.downcase)
        error("#{relative(path)} exposes sensitive or denied dimension #{column.inspect}")
      end
    end

    Array(mod["joinPaths"]).each do |join_path|
      check_extra_keys(join_path, JOIN_PATH_KEYS, "#{relative(path)} joinPath")
      type = join_path["type"]
      error("#{relative(path)} joinPath type #{type.inspect} is not supported by Steep YAML") unless JOIN_PATH_TYPE_VALUES.include?(type)

      from_column = join_path.dig("from", "column")
      to_table = join_path.dig("to", "table")
      to_column = join_path.dig("to", "column")
      target_model_name = table_to_model_name[to_table]

      error("#{relative(path)} joinPath from column #{from_column.inspect} does not exist on #{table}") unless model_columns.include?(from_column)
      if target_model_name.nil?
        error("#{relative(path)} joinPath target table #{to_table.inspect} is unknown")
      elsif !columns_by_model.fetch(target_model_name).include?(to_column)
        error("#{relative(path)} joinPath target #{to_table}.#{to_column} does not exist")
      end
    end

    Array(mod["metrics"]).each do |metric|
      identifier = metric["identifier"]
      metric_ids[identifier] << relative(path) if identifier
      check_extra_keys(metric, METRIC_KEYS, "#{relative(path)} metric #{identifier}")
      calculation = metric["calculation"]
      error("#{relative(path)} metric #{identifier} has unsupported calculation #{calculation.inspect}") unless CALCULATION_VALUES.include?(calculation)

      case calculation
      when "sum"
        error("#{relative(path)} metric #{identifier} sum metric is missing value") unless metric["value"]
      when "count-distinct"
        error("#{relative(path)} metric #{identifier} count-distinct metric is missing distinct_on") unless metric["distinct_on"]
      when "ratio"
        %w[numerator denominator format].each do |key|
          error("#{relative(path)} metric #{identifier} ratio metric is missing #{key}") unless metric[key]
        end
      when "custom-value"
        error("#{relative(path)} metric #{identifier} custom-value metric is missing sql_expression") unless metric["sql_expression"]
      when "custom-ratio"
        %w[numerator_sql denominator_sql format].each do |key|
          error("#{relative(path)} metric #{identifier} custom-ratio metric is missing #{key}") unless metric[key]
        end
      end

      %w[time value distinct_on numerator denominator].each do |key|
        next unless metric[key]

        ref = column_ref(metric[key])
        if ref.nil?
          error("#{relative(path)} metric #{identifier} #{key} must be table.column: #{metric[key].inspect}")
          next
        end

        ref_table, ref_column = ref
        ref_model = table_to_model_name[ref_table]
        if ref_model.nil?
          error("#{relative(path)} metric #{identifier} #{key} references unknown table #{ref_table}")
        elsif !columns_by_model.fetch(ref_model).include?(ref_column)
          error("#{relative(path)} metric #{identifier} #{key} references missing column #{ref_table}.#{ref_column}")
        end
      end

      Array(metric["dimensions"]).each do |dimension_ref|
        next if dimension_ref == "this.*"

        if dimension_ref.include?(".")
          ref = column_ref(dimension_ref)
          if ref.nil?
            error("#{relative(path)} metric #{identifier} dimension #{dimension_ref.inspect} is not table.column")
            next
          end

          ref_table, ref_column = ref
          ref_model = table_to_model_name[ref_table]
          if ref_model.nil? || !columns_by_model.fetch(ref_model, []).include?(ref_column)
            error("#{relative(path)} metric #{identifier} dimension references missing #{dimension_ref}")
          end
        elsif !local_dimensions.include?(dimension_ref)
          error("#{relative(path)} metric #{identifier} dimension #{dimension_ref.inspect} is not declared locally")
        end
      end

      Array(metric["filters"]).each do |filter|
        check_extra_keys(filter, FILTER_KEYS, "#{relative(path)} metric #{identifier} filter")
        filter_table = filter["table"] || table
        filter_model = table_to_model_name[filter_table]
        filter_column = filter["column"]

        if filter_model.nil? || !columns_by_model.fetch(filter_model, []).include?(filter_column)
          error("#{relative(path)} metric #{identifier} filter references missing #{filter_table}.#{filter_column}")
          next
        end

        allowed_values = Array(models_by_name(filter_model).fetch("columns").find { |col| col["name"] == filter_column }&.dig("meta", "example_values")).map(&:to_s)
        expression_values = filter["operator"] == "in" ? filter["expression"].to_s.split(",") : [filter["expression"].to_s]
        missing_values = expression_values.reject { |value| allowed_values.include?(value) }
        unless missing_values.empty?
          error("#{relative(path)} metric #{identifier} filter values not in schema.yml example_values for #{filter_column}: #{missing_values.join(', ')}")
        end
      end

      Array(metric["slices"]).each do |slice|
        check_extra_keys(slice, SLICE_KEYS, "#{relative(path)} metric #{identifier} slice")
        filter = slice["filter"] || {}
        check_extra_keys(filter, FILTER_KEYS, "#{relative(path)} metric #{identifier} slice filter")
        filter_table = filter["table"] || table
        filter_model = table_to_model_name[filter_table]
        filter_column = filter["column"]
        next unless filter_model && filter_column

        allowed_values = Array(models_by_name(filter_model).fetch("columns").find { |col| col["name"] == filter_column }&.dig("meta", "example_values")).map(&:to_s)
        expression_values = filter["operator"] == "in" ? filter["expression"].to_s.split(",") : [filter["expression"].to_s]
        missing_values = expression_values.reject { |value| allowed_values.include?(value) }
        unless missing_values.empty?
          error("#{relative(path)} metric #{identifier} slice filter values not in schema.yml example_values for #{filter_column}: #{missing_values.join(', ')}")
        end
      end
    end
  end

  metric_ids.each do |identifier, locations|
    error("#{label} metric identifier #{identifier.inspect} is duplicated in #{locations.join(', ')}") if locations.length > 1
  end
end

def models_by_name(model_name)
  @models_by_name.fetch(model_name)
end

@models_by_name = models_by_name

validate_yaml_collection(
  Dir[File.join(ROOT, "modules/*.yaml")].sort,
  "modules",
  table_to_model_name,
  columns_by_model,
  column_meta_by_model,
  deny_list
)

Dir[File.join(ROOT, "examples/expected-output/*")].select { |path| File.directory?(path) }.sort.each do |scenario_dir|
  validate_yaml_collection(
    Dir[File.join(scenario_dir, "*.yaml")].sort,
    relative(scenario_dir),
    table_to_model_name,
    columns_by_model,
    column_meta_by_model,
    deny_list
  )
end

if @errors.empty?
  puts "Semantic contract validation passed."
else
  warn "Semantic contract validation failed:"
  @errors.each { |message| warn "- #{message}" }
  exit 1
end
