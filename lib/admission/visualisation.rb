require 'sinatra/base'
require 'sinatra/json'
require 'pathname'
require 'ostruct'

class Admission::Visualisation < Sinatra::Base
  ASSETS_PATH = Pathname.new(__FILE__).join('..', '..', '..', 'visualisation')

  enable :inline_templates

  set :url_prefix, nil
  set :js_entry, ASSETS_PATH.join('dist', 'admission_visualisation.js')

  get '/' do
    ViewHelper.new(url_prefix: settings.url_prefix).render_view
  end

  get '/admission_visualisation.js' do
    send_file settings.js_entry
  end

  get '/admission_data.json' do
    json Admission::Visualisation.admission_data_to_js(
        **settings.admission_data)
  end

  def self.admission_data_to_js order:, rules:, arbitrator: Admission::ResourceArbitration, **_
    js_data = {}
    order = order.call if Proc === order
    rules = rules.call if Proc === rules

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

    actions_reduce = -> (index) {
      index.to_a.map do |action, action_index|
        action_index = action_index.to_a.map do |privilege, rule|
          if rule.is_a? Proc
            rule = 'proc'
          end

          [privilege.text_key, rule]
        end

        [action, Hash[action_index]]
      end
    }

    rules = if arbitrator == Admission::Arbitration
      single_scope = actions_reduce[rules]
      [['-non-scoped-', Hash[single_scope]]]

    elsif arbitrator == Admission::ResourceArbitration
      rules.to_a.map do |scope, scope_index|
        scope_index = actions_reduce[scope_index]
        [scope, Hash[scope_index]]
      end

    else
      raise "not implemented for #{arbitrator.name}"

    end
    js_data[:rules] = Hash[rules]

    js_data
  end

end


class ViewHelper < OpenStruct

  def render_view
    <<-HEREDOC
<!DOCTYPE html>
<html>
<head>
<title>Admission</title>
</head>
<body class='flex-column'>

<div data-url='#{url_prefix}/admission_data.json' id='admission-visualisation'></div>
<script src='#{url_prefix}/admission_visualisation.js'></script>

</body>
</html>
    HEREDOC
  end

end