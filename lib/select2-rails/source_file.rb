require "thor"
require "json"
require "httpclient"

class SourceFile < Thor
  include Thor::Actions

  desc "fetch source files", "fetch source files from GitHub"
  option :force, type: :boolean, default: false, aliases: :f
  option :latest, type: :boolean, default: false, aliases: :l
  def fetch
    filtered_tags = fetch_tags
    tag = if options[:latest]
            filtered_tags.last
          else
            select("Which tag do you want to fetch?", filtered_tags)
          end.value
    self.destination_root = "app/assets"
    remote = "https://github.com/ivaynberg/select2"
    get "#{remote}/raw/#{tag}/select2.png", "images/select2.png"
    get "#{remote}/raw/#{tag}/select2x2.png", "images/select2x2.png"
    get "#{remote}/raw/#{tag}/select2-spinner.gif", "images/select2-spinner.gif"
    get "#{remote}/raw/#{tag}/select2.css", "stylesheets/select2.css"
    get "#{remote}/raw/#{tag}/select2.js", "javascripts/select2.js"
    languages.each do |lang|
      get(
        "#{remote}/raw/#{tag}/select2_locale_#{lang}.js",
        "javascripts/select2_locale_#{lang}.js",
        force: options[:force]
      )
    end
  end

  desc "convert css to css.erb file", "make css preprocess with erb"
  def convert
    self.destination_root = "app/assets"
    inside destination_root do
      run("cp stylesheets/select2.css stylesheets/select2.css.erb")
      gsub_file 'stylesheets/select2.css.erb', %r/url\(([^\)]*)\)/, 'url(<%= asset_path(\1) %>)'
    end
  end

  desc "clean up useless files", "clean up useless files"
  def cleanup
    self.destination_root = "app/assets"
    remove_file "stylesheets/select2.css"
  end

  private
  def fetch_tags
    http = HTTPClient.new
    response = JSON.parse(http.get("https://api.github.com/repos/ivaynberg/select2/tags").body)
    tags = response.map{|tag| tag["name"]}.sort

    [].tap do |result|
      tags.each_with_index do |tag, index|
        result << OpenStruct.new(index: index + 1, value: tag)
      end
    end
  end
  def languages
    [ "ar", "bg", "ca", "cs", "da", "de", "el", "es", "et", "eu", "fa", "fi", "fr", "gl", "he", "hr",
      "hu", "id", "is", "it", "ja", "ko", "lt", "lv", "mk", "ms", "nl", "no", "pl", "pt-BR",
      "pt-PT", "ro", "ru", "sk", "sv", "th", "tr", "ua", "vi", "zh-CN", "zh-TW"
    ].sort
  end
  def select msg, tags
    tags.each do |tag|
      say("#{tag.index}. #{tag.value}")
    end
    result = ask(msg).to_i
    tags[result - 1]
  end
end
