require 'pathname'
require 'json'

class Admission::VisualisationApp

  def initialize **settings
    order = settings[:order] || (raise 'order not defined, cannot visualise data')
    raise 'order must be a Proc' unless Proc === order

    settings[:js_entry] ||= Pathname.new(__FILE__).join('..', '..', '..',
        'visualisation', 'dist', 'app.js')

    @settings = settings
  end

  def call env
    case env['PATH_INFO'].to_s
      when %r~^/(\.html)?$~
        [
            200,
            {'Content-Type' => 'text/html'},
            [render_page]
        ]

      when %r~/app\.js~
        [
            200,
            {'Content-Type' => 'application/js'},
            [File.read(@settings[:js_entry])]
        ]

      when %r~/data\.json~
        [
            200,
            {'Content-Type' => 'application/json'},
            [render_data(@settings[:order].call)]
        ]

      else
        [
            404,
            {'Content-Type' => 'text/html'},
            ['Admission::VisualisationApp : page not found']
        ]

    end
  end

  def render_page
    data_url = "#{@settings[:url_prefix]}/data.json"
    script_url = "#{@settings[:url_prefix]}/app.js"

    <<-HEREDOC
<!DOCTYPE html>
<html>
<head>
<title>Admission</title>
</head>
<body class='flex-column'>

<div data-url="#{data_url}" id="admission-visualisation"></div>
<script src="#{script_url}"></script>

</body>
</html>
    HEREDOC
  end

  def render_data privileges:, rules:, arbitrator: Admission::ResourceArbitration
    js_data = {}

    top_levels = []
    privileges = privileges.values.inject Array.new do |arr, levels|
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

    JSON.generate js_data
  end

end