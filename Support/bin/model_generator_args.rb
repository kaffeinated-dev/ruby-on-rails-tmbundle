# Print the ‘bin/rails generate model’ arguments for a create_table migration,
# one per line: the table name (the generator singularizes it), the attributes,
# and options. Reads the migration from standard input.
#
# usage: ruby model_generator_args.rb [line]
#
# When several tables are created, the one around «line» is used (default: the
# first). Exits with status 1 and a message when there is no create_table.
#
# Plain Ruby without dependencies, so it runs with any Ruby version from 2.6.

COLUMN_TYPES = %w[
  bigint binary blob boolean date datetime decimal float integer json numeric string text time timestamp virtual
  bigserial bit bit_varying cidr citext daterange hstore inet interval int4range int8range jsonb ltree macaddr money
  numrange oid point line lseg box path polygon circle serial tsrange tstzrange tsvector uuid xml timestamptz enum
  tinyblob mediumblob longblob tinytext mediumtext longtext unsigned_integer unsigned_bigint
]

Table = Struct.new(:name, :options, :body, :first_line, :last_line)

def tables(source)
  lines = source.lines
  result = []
  lines.each_with_index do |line, i|
    next unless line =~ /^(\s*)create_table\s*\(?\s*[:"']([\w.]+)["']?(.*)$/
    indent, name, options = $1, $2, $3
    last = (i + 1...lines.size).find { |j| lines[j] =~ /^#{indent}end\b/ } || lines.size - 1
    result << Table.new(name, options, lines[i + 1...last], i + 1, last + 1)
  end
  result
end

# Parse the option list of a column definition, e.g. ‘precision: 10, scale: 2’.
def option(options, key)
  options[/\b#{key}:\s*([^,]+?)\s*(?:,|\z)/, 1] || options[/:#{key}\s*=>\s*([^,]+?)\s*(?:,|\z)/, 1]
end

def attributes(table)
  table.body.flat_map do |line|
    next [] unless line =~ /^\s*\w+\.(\w+)\s*\(?\s*(.*?)\s*\)?\s*(?:#.*)?$/
    method, rest = $1, $2
    names = rest.scan(/(?:\A|,)\s*[:"']([\w]+)["']?(?=\s*(?:,|\z))/).flatten
    options = rest.sub(/\A(?:\s*[:"'][\w]+["']?\s*,?)+/, "")

    case method
    when "references", "belongs_to"
      modifier = option(options, "polymorphic") == "true" ? "{polymorphic}" : ""
      names.map { |name| "#{name}:references#{modifier}" }
    when "column"
      name, type = rest.scan(/[:"']([\w]+)["']?/).flatten
      name && type ? ["#{name}:#{type}"] : []
    when *COLUMN_TYPES
      modifier = case method
                 when "decimal", "numeric"
                   precision, scale = option(options, "precision"), option(options, "scale")
                   precision ? "{#{[precision, scale].compact.join(",")}}" : ""
                 when "string", "text", "binary", "integer"
                   (limit = option(options, "limit")) ? "{#{limit}}" : ""
                 else ""
                 end
      index = case option(options, "index")
              when nil, "false" then ""
              when /unique:\s*true/ then ":uniq"
              else ":index"
              end
      names.map { |name| "#{name}:#{method}#{modifier}#{index}" }
    else # timestamps, index, check_constraint, …
      []
    end
  end
end

source = $stdin.read
all = tables(source)
if all.empty?
  puts "This is not a migration that creates a table: there is no create_table."
  exit 1
end

line = ARGV[0].to_i
table = all.find { |t| line.between?(t.first_line, t.last_line) } || all.first

puts table.name
puts attributes(table)
puts "--primary-key-type=#{$1}" if table.options =~ /\bid:\s*:(\w+)/ && $1 != "false"
