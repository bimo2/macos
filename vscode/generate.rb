require 'json'
require 'fileutils'

def read_define_txt(file)
  themes = []
  tokens = {}

  File.foreach(file) do |line|
    line.strip!
    next if line.empty?

    if line.start_with?('----') && line.end_with?('----')
      theme = line.gsub('----', '').strip.downcase
      themes << theme.gsub(' ', '')
    else
      key_value = line.split(/\s+/, 2)
      tokens[key_value[0]] = key_value[1] if key_value.length == 2
    end
  end

  [themes, tokens]
end

def with_alpha(value, hex_value)
  hex_value = hex_value.rjust(2, '0') if hex_value.length < 2
  value + hex_value
end

def map_colors(theme, colorset, tokens)
  color_value = lambda do |token|
    token += ".d" if colorset == "dark"
    value = tokens["#{theme}.#{token}"]
    value ||= tokens[token]
    value
  end

  options = {
    "option_1" => lambda { color_value.call("accent") },
    "option_2" => lambda { with_alpha(color_value.call("accent"), "10") },
  }

  options.transform_values(&:call)
end

def generate(txt_file)
  themes, tokens = read_define_txt(txt_file)

  themes.each do |theme|
    folder = "dist/#{theme}"
    FileUtils.mkdir_p(folder) unless File.directory?(folder)

    %w(light dark).each do |colorset|
      json = {
        "name" => tokens[colorset == "dark" ? "#{theme}.d" : theme],
        "colors" => map_colors(theme, colorset, tokens),
        "semanticHighlighting" => true,
        "tokenColors" => [],
      }

      file_name = colorset == "dark" ? "#{theme}-d" : theme

      File.open("#{folder}/#{file_name}.json", "w") do |file|
        file.write(JSON.pretty_generate(json))
      end
    end
  end
end

generate("define.txt")
