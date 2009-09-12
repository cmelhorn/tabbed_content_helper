# Provides a tabbed_content helper method for easily creating a set of tabbed panels:
#
#   tabbed_content do |tab|
#     tab.make_tab('profile', "<p>Content for the profile panel</p>")
#     tab.make_tab('email', "<p>Content for the email panel")
#     tab.activity('recent activity', "<p>Content for the activity panel</p>")
#   end
#
# == Author
# Charles Melhorn, http://the.dourlad.com
#
# == Copyright
# Copyright (c) 2009 Charles Melhorn. Licensed under the MIT License:
# http://www.opensource.org/licenses/mit-license.php

module TabbedContentHelper

  class TabBuilder
    attr_reader :tabs, :active_tab

    def initialize
      @tabs = []
      @active_tab = 0
    end

    def make_tab(label, panel_body, active_flag = nil)
      @tabs << {'label' => label, 'panel_body' => panel_body, 'id' => id_from_label(label), 'index' => @tabs.size}
      @active_tab = @tabs.last['index'] if !active_flag.nil? and active_flag == :active
    end

    def method_missing(method_symbol, *args)
      if (args.length == 2 || args.length == 3)
        @tabs << {'label' => args[0], 'panel_body' => args[1], 'id' => method_symbol.to_s, 'index' => @tabs.size}
        @active_tab = @tabs.last['index'] if !args[2].nil? and args[2] == :active
      else
        super
      end
    end

    private
    def id_from_label(label)
      id = label.gsub(/['?:,]/, "").gsub(/( - )|( +)/, "-").downcase
    end
  end

  # ==== Options
  # * <tt>:html_only</tt> - If true, only html markup is generated. Set this if you want to
  #   use custom javascript or some library other than prototype/scriptaculous (e.g. jQuery)
  #   for tab control. Default is +false+.
  # * <tt>:effect</tt> - Controls the effect used to show or hide the active tab. Valid values
  #   are <tt>nil</tt> and <tt>:appear</tt>. Default is +nil+.
  #
  def tabbed_content(container_id = "tabs", options = {})
    options[:html_only] ||= false
    options[:effect] ||= nil
    options[:indent] ||= 0
     
    # pass tab builder instance for block to use to create tabs
    tb = TabBuilder.new
    yield(tb)

    # generate html
    html = ""

    html << content_tag(:div, :id => container_id) do 
      "\n  " +
      content_tag(:ul, :id => 'tab_headers') do 
        tb.tabs.collect{ |tab| "\n    " + content_tag(:li, link_to(tab['label'], "##{tab['id']}"),
                                                      :id => "tab_header_#{tab['id']}",
                                                      :class => tb.active_tab == tab['index'] ? "ui-tabs-selected" : nil)
                       }.join + "\n  "
      end +
      "\n  " +
      content_tag(:div, :id => 'tab_panels') do 
        tb.tabs.collect{ |tab| "\n    " + content_tag(:div, "<div>#{tab['panel_body']}</div>",
                                                      :id => "tab_panel_#{tab['id']}",
                                                      :style => tb.active_tab == tab['index'] ? "display: block;" : "display: none;")
                       }.join + "\n  "
      end + 
      "\n"
    end

    # generate javascript, a la ajax helpers
    js = ""

    unless options[:html_only] == true
      js << "\n"
      js << '<script type="text/javascript">'
      js << render_tabpanel_hide_js(options[:effect])
      js << render_tabpanel_show_js(options[:effect])
      js << render_tabbed_content_js()
      js << '</script>'
      js << "\n"  
    end

    return html + js
  end

  private

  def render_tabpanel_hide_js(effect)
    effect_code = case(effect)
    when :appear
        "Effect.toggle(tabId, 'appear', {duration:0.5, queue:{scope:'tabbed_content'}});"
    else
        "$(tabId).style.display = 'none';"
    end

    js = %Q!
      function hideTabPanel(tabId){
        #{effect_code}
      }!
  end

  def render_tabpanel_show_js(effect)
    effect_code = case(effect)
    when :appear
        "Effect.toggle(tabId, 'appear', {duration:0.5, queue:{scope:'tabbed_content', position:'end'}});"
    else
        "$(tabId).style.display = 'block';"
    end

    js = %Q!
      function showTabPanel(tabId){
        #{effect_code}
      }!
  end  

  def render_tabbed_content_js
    js = <<-END_JS_CODE

      function displayTab(event)
      {
        var selected_tab = event.element().getAttribute('href').substring(1);

        // if selected tab is not already active
        if ($('tab_panel_'+selected_tab).style.display == 'none')
         {
           // hide all tabs
           $$('#tab_headers a').each(function(link){
             var tab_id = link.getAttribute('href').substring(1);
             $('tab_header_' + tab_id).removeClassName('ui-tabs-selected');
             if ($('tab_panel_' + tab_id).style.display != 'none')
               hideTabPanel('tab_panel_' + tab_id);
           });

           // display the selected tab
           $('tab_header_' + selected_tab).addClassName('ui-tabs-selected');
           showTabPanel('tab_panel_' + selected_tab);  
         }

        event.stop();
      }

      document.observe("dom:loaded", function() {
        $$('#tab_headers a').each(function(link){
          link.observe('click', displayTab);
        });
      });

    END_JS_CODE
  end

end
