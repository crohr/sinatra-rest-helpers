require 'rack'

module Sinatra
  # 
  # Include it with:
  #   class App < Sinatra::Base
  #     helpers Sinatra::RestHelpers
  #   end
  # 
  module RestHelpers
    INFINITY = 1/0.0
    # e.g.:
    #   get '/x/y/z' do
    #     provides "application/json", :xml, :zip, "text/html;level=5"
    #   end
    def provides *formats
      generate_type_hash = Proc.new{ |header| 
        type, *params = header.split(/;\s*/)
        Hash[*params.map{|p| p.split(/\s*=\s*/)}.flatten].merge("type" => type)
      }
      supported_formats = formats.map do |f| 
        # selects the correct mime type if a symbol is given
        f.is_a?(Symbol) ? ::Rack::Mime::MIME_TYPES[".#{f.to_s}"] : f
      end.compact.map do |f|
        generate_type_hash.call(f)
      end
      # request.accept is an Array
      accepted_formats = request.accept.map do |f| 
        generate_type_hash.call(f)
      end
      selected_format = supported_formats.detect{ |supported_format| 
        !accepted_formats.detect{ |accepted_format| 
          Regexp.new(Regexp.escape(accepted_format["type"]).gsub("\\*", ".*?"), Regexp::IGNORECASE) =~ supported_format["type"] &&
            (accepted_format["level"] || INFINITY).to_f >= (supported_format["level"] || 0).to_f
        }.nil?
      }      
      if selected_format.nil?
        halt 406, supported_formats.map{|f| 
          output = f["type"]
          output += ";level=#{f["level"]}" if f.has_key?("level")
        }.join(", ")
      else
        response.headers['Content-Type'] = "#{selected_format["type"]}#{selected_format["level"].nil? ? "" : ";level=#{selected_format["level"]}"}"
      end
    end
  end

end
