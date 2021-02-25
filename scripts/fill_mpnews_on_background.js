// ==UserScript==
// @name         自动填入最新 Elixir RSS 内容
// @namespace    http://tampermonkey.net/
// @version      0.1
// @description  try to take over the world!
// @author       feng19
// @updateURL    https://raw.githubusercontent.com/feng19/elixir-rss/master/scripts/fill_mpnews_on_background.js
// @match        https://mp.weixin.qq.com/cgi-bin/appmsg*
// @connect      elixir-rss.feng19.com
// @connect      localhost
// @run-at       context-menu
// @grant        GM_xmlhttpRequest
// @grant        unsafeWindow
// ==/UserScript==

(function() {
    'use strict';

    console.log("============ start ============");
    let today = new Date();
    $("#title").val("Elixir Status |> " + today.toLocaleDateString() + " RSS");
    $("#author").val("feng19");

    GM_xmlhttpRequest({
        "method": "GET",
        //"url": "http://localhost:4000/api/preview",
        "url": "https://elixir-rss.feng19.com/api/preview",
        "onload": function (result) {
            let json = JSON.parse(result.response);
            console.log("code: ", json.code);
            if(json.code == 200) {
                let ue = UE.getEditor("js_editor");
                ue.setContent(json.content);
                console.log("last_updated:", json.last_updated);
                $("#js_description").val("Elixir RSS");
            }
        }
    });

    $("input[name='file_id']").val("100000014");
    let pic_url = "https://mmbiz.qlogo.cn/mmbiz_jpg/9x6HiaxYPqJPe0DSzC1rWGLiaiayKjEXgicNkLkATm4mh9GNSDBOLPMSvSCRXrPlIucIyTiaJ5eoTNI5nWdeZQianOPg/0?wx_fmt=jpeg"
    $("#js_cover_area .js_cover_preview").attr("style", `background-image: url("${pic_url}");`);
    $("input[name='cdn_url']").val("https://mmbiz.qlogo.cn/mmbiz_jpg/9x6HiaxYPqJPe0DSzC1rWGLiaiayKjEXgicNkLkATm4mh9GNSDBOLPMSvSCRXrPlIucIyTiaJ5eoTNI5nWdeZQianOPg/0?wx_fmt=jpeg");
    $("input[name='cdn_url_back']").val("https://mmbiz.qpic.cn/mmbiz_png/9x6HiaxYPqJOCzWWhxZp2h14RsHtxtnL1zIGm4Wff0fnMtlzibojLyIUcLDFt8bVQiaiaPgLiaib3QkHnMt6dYJIBEHw/0?wx_fmt=png");
    $("input[name='show_cover_pic']").val("0");

    // todo 原文链接："feng19.github.io/elixir-rss"
    console.log("============ end ============");
})();