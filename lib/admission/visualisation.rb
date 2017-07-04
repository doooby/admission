require 'sinatra/base'
require 'sinatra/json'
require 'haml'
require 'pathname'

class Admission::Visualisation < Sinatra::Base
  ASSETS_PATH = Pathname.new(__FILE__).join('..', '..', '..', 'visualisation')

  enable :inline_templates

  set :js_entry, ASSETS_PATH.join('dist', 'admission_visualisation.js')

  get '/' do
    haml :index
  end

  get '/admission_visualisation.js' do
    send_file settings.js_entry
  end

  get '/admission_data' do
    json Admission::Visualisation.admission_data_to_js(
        **settings.admission_data)
  end

  def self.admission_data_to_js order:, rules:, arbitrator:, **_
    js_data = {}

    top_levels = []
    privileges = order.values.inject Array.new do |arr, levels|
      tops, others = levels.to_a.partition{|key, _| key == :'^'}
      tops.first[1].tap{|privilege| top_levels << privilege.text_key}

      others.each do |_, privilege|
        arr << {name: privilege.name, level: privilege.level,
            inherits: privilege.inherited && privilege.inherited.map(&:text_key)}
      end

      arr
    end

    js_data[:privileges] = privileges
    js_data[:top_levels] = top_levels
    js_data[:levels] = privileges.inject Hash.new do |hash, p|
      (hash[p[:name]] ||= []) << p[:level]
      hash
    end

    rules = if arbitrator == Admission::Arbitration
      single_scope = rules.to_a.map do |scope, index|
        index = index.to_a.map do |privilege, rule|
          if rule.is_a? Proc
            rule = 'proc'
          end

          [privilege.text_key, rule]
        end

        [scope, Hash[index]]
      end
      [['-non-scoped-', Hash[single_scope]]]

    # elsif arbitrator == ResourceArbitration

    else
      raise "not implemented for #{arbitrator.name}"

    end
    js_data[:rules] = Hash[rules]

    js_data
  end

end

__END__

@@ layout
!!! 5
%html
  %head
    %title= 'Admission'
  %body.flex-column
    = yield

@@ index
#admission-visualisation(data-url="/admission_data")
%script(src="/admission_visualisation.js")