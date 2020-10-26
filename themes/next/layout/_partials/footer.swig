
{%- if theme.footer.powered %}
  <div class="BbeiAn-info">
    {{ __('')}}
      <a target="_blank"  href="http://www.beian.miit.gov.cn/">浙ICP备17047146号</a>
      </a>
    </div>
{%- endif %}

{%- if theme.add_this_id %}
  <div class="addthis_inline_share_toolbox">
    <script src="//s7.addthis.com/js/300/addthis_widget.js#pubid={{ theme.add_this_id }}" async="async"></script>
  </div>
{%- endif %}

{{- next_inject('footer') }}
