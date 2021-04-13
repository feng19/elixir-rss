# Elixir-RSS (WIP)

Elixir-RSS 内容发布网站

内容来源：
* [ElixirStatus](https://elixirstatus.com/) - WIP

内容来源 - TODO：
* [ElixirForum](https://elixirforum.com/)
* [ElixirRadar](https://elixir-radar.com/)
* [ElixirWeekly](https://elixirweekly.net/)
* [ElixirJobs](https://elixirjobs.net/)
* [PlanetErlang](http://www.planeterlang.com/)

本项目的作用是将以上来源的信息聚合发布到微信公众号

![请关注公众号](wechat_qrcode.png)

## Run Project

```shell
WECHAT_SECRET="" WECHAT_TOKEN="" TOKEN_SALT="" PORT=4000 iex -S mix phx.server
```