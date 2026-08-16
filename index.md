---
layout: default
title: Home
---

<div class="home-intro prose">

<h1> Hi, my name is <a href="https://jonathanfrei.com">Jonathan Frei</a >.</h1>

<p>Pardon the mess while I get things reset up online. You can email me at
<a href="javascript:location='mailto:\u0068\u0069\u0040\u006a\u006f\u006e\u0061\u0074\u0068\u0061\u006e\u0066\u0072\u0065\u0069\u002e\u0063\u006f\u006d';void 0">hi [@] jonathan frei dot com</a>
or reach me on X at <a href="https://x.com/jonathanfrei">@jonathanfrei</a> although I don't post anymore.</p>

<p>Earlier iterations of this site are still available online. I published <a href="http://v1.jonathanfrei.com">v1 on Blogger</a> from 2009 to 2010; <a href="https://v2.jonathanfrei.com">v2 on Tumblr</a> from 2010 to 2014; <a href="https://v3.jonathanfrei.com">v3 on a self-hosted Wordpress</a> from 2014 to 2022 (online version is now a static copy hosted in an S3 bucket); <a href="https://v4.jonathanfrei.com">v4 lives in Github</a> and is distributed through Cloudflare from 2022 to 2026.</p>

<p>The <a href="https://jonathanfrei.com">current site</a> is built with Jekyll, deployed via GitHub Actions, and served through Cloudflare.</p>

<p>Short posts live on the <a href="/blog">blog</a>. Longer writing will appear as articles. A portfolio or photo galleries may come later.</p>


</div>




<h2 class="section-title">Recent posts and links</h2>

{% include stream-list.html items=page.stream_items %}

{% include pagination.html %}
