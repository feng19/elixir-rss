// ==UserScript==
// @name         自动填入最新 Elixir RSS 内容
// @namespace    http://tampermonkey.net/
// @version      0.1.2
// @description  try to take over the world!
// @author       feng19
// @updateURL    https://raw.githubusercontent.com/feng19/elixir-rss/master/scripts/fill_mpnews_on_background.js
// @match        https://mp.weixin.qq.com/cgi-bin/appmsg*
// @connect      elixir-rss.feng19.com
// @connect      localhost
// @run-at       context-menu
// @grant        GM_setValue
// @grant        GM_getValue
// @grant        GM_xmlhttpRequest
// @grant        unsafeWindow
// ==/UserScript==

(function() {
  'use strict';
  const LAST_UPDATED = 'last_updated';

  console.log("============ start ============");
  let today = new Date();
  // 标题
  $("#title").val("Elixir Status |> " + today.toLocaleDateString() + " RSS");
  // 作者
  $("#author").val("feng19");
  let last_updated = GM_getValue(LAST_UPDATED, "0");
  console.log("last_updated:", last_updated);
  //let url = "http://localhost:4000/api/preview?last_updated=" + last_updated;
  let url = "https://elixir-rss.feng19.com/api/preview?last_updated=" + last_updated;

  // 封面
  $("input[name='file_id']").val("100000014");
  let pic_url = "https://mmbiz.qlogo.cn/mmbiz_jpg/9x6HiaxYPqJPe0DSzC1rWGLiaiayKjEXgicNkLkATm4mh9GNSDBOLPMSvSCRXrPlIucIyTiaJ5eoTNI5nWdeZQianOPg/0?wx_fmt=jpeg"
  $("#js_cover_area .js_cover_preview").attr("style", `background-image: url("${pic_url}");`);
  $("input[name='cdn_url']").val("https://mmbiz.qlogo.cn/mmbiz_jpg/9x6HiaxYPqJPe0DSzC1rWGLiaiayKjEXgicNkLkATm4mh9GNSDBOLPMSvSCRXrPlIucIyTiaJ5eoTNI5nWdeZQianOPg/0?wx_fmt=jpeg");
  $("input[name='cdn_url_back']").val("https://mmbiz.qpic.cn/mmbiz_png/9x6HiaxYPqJOCzWWhxZp2h14RsHtxtnL1zIGm4Wff0fnMtlzibojLyIUcLDFt8bVQiaiaPgLiaib3QkHnMt6dYJIBEHw/0?wx_fmt=png");
  $("input[name='show_cover_pic']").val("0");

  // 原文链接
  $("#js_article_url_area input[name='source_url_checked']").attr("checked", "checked");
  $("#js_article_url_area .frm_checkbox_label").addClass("selected");
  $("#js_article_url_area .js_article_url_allow_click").addClass("open");
  $("#js_article_url_area .article_url_setting").attr("style", "display: inline-block;");
  $("#js_article_url_area .article_url_setting").text("https://feng19.github.io/elixir-rss");

  GM_xmlhttpRequest({
    "method": "GET",
    "url": url,
    "onload": function (result) {
      let json = JSON.parse(result.response);
      console.log("code: ", json.code);
      if(json.code == 200) {
        // 内容
        let ue = UE.getEditor("js_editor");
        let content = json.content;
        if(content.length == 0) {
          ue.setContent("<p>今日无内容</p>");
        } else {
          ue.setContent(json.content);
        }

        $("#js_article_url_area .article_url_setting").text("https://elixir-rss.feng19.com?last_updated=" + last_updated);

        console.log("last_updated:", json.last_updated);
        GM_setValue(LAST_UPDATED, json.last_updated);
      }
      // 摘要
      $("#js_description").val("Elixir RSS");
      $("#js_description_area .frm_counter").text("10/120");
      console.log("============ end ============");
    }
  });
})();