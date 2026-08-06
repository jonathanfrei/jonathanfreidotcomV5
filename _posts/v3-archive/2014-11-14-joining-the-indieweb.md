---
title: "Joining the IndieWeb"
date: 2014-11-14 11:53:21 -0500
categories: [blog]
tags: [homesteading, Indieweb, "online identity"]
wordpress_id: "5176"
---

Over the last couple of months, I've been working on moving my personal site (this site) over to WordPress on a VPS. The move was inspired by a desire to adopt the principles of the <a href="http://indiewebcamp.com">IndieWeb movement</a> for my personal home on the web.

Owning my data is important to me. Liberating the things I post online from the corporate silos like <a href="https://www.facebook.com/jonathan.e.frei">Facebook</a>, <a href="https://twitter.com/jonathanfrei">Twitter</a>, <a href="http://v2.jonathanfrei.com">Tumblr</a>, and <a href="https://www.flickr.com/photos/jonathanfrei/">Flickr</a> means I can own my data and control how it appears. Mozilla expressed the sentiment well with their <a href="https://www.youtube.com/watch?v=LtOGa5M8AuU">Choose Independent video</a>.

I'm not quitting Facebook, Twitter, or any other social site as many have done or threatened to do, so I don't have to delete my accounts (<a href="http://jonathanfrei.com/2013/09/how-to-disappear-from-the-web">which isn't easy to do</a>). Moving to the IndieWeb doesn't mean I have to give up using Facebook and Twitter, which is good because that's where my friend are.

Most of what I post to my site will show up in one or both of those places. The difference is that nothing I post shows up <em>only</em> in those places. I will have the original post on my site and the silos will get a syndicated copy with a link back to the original.

I used to host my site on <a href="http://v2.jonathanfrei.com/">Tumblr</a>. Moving it to <a href="https://www.digitalocean.com/?refcode=b7969688e924">DigitalOcean</a> provided <a href="http://jonathanfrei.com/2014/10/digitalocean-difference">immediate results</a> in the speed and performance of the pages. Not only is page load time greatly increased, I also have more control over what elements are loaded on the page.

With Tumblr, there were several calls out to Tumblr's analytics and back-end services. After Yahoo! bought Tumblr, there were even more beacons and analytics code running with each page view. This slowed things down and creeped me out. There was little to no transparency as to what was being done with all this data. I still use Google Analytics on this site (for now), but at least I have some understanding of how that data is collected and used.

<h2>Implementing the IndieWeb</h2>

The <a href="http://indiewebcamp.com/Wordpress">WordPress page of Indiewebcamp.com</a> was very helpful in figuring out the IndieWebify this site. It has a fairly comprehensive getting started guide, along with links to the plug-ins, tools, and services that can help my site talk to other sites on the web.

So far, I've implemented a number of the major IndieWeb components including:

<ul>
    <li><strong>IndieAuth</strong>: This lets me login to my site and others using my domain as the method of authentication. This is more secure than just relying on user names and passwords</li>
    <li><strong>Microformats</strong>: The additional markup to my posts help them to show up correctly on other sites and in webmention comments.</li>
    <li><strong>POSSE</strong>: This is an acronym for "Publish on your own site, syndicate elsewhere". Currently I'm using <a href="http://www.nextscripts.com/">NextScripts' SNAP</a> plug-in along with Facebook, Twitter, and Flickr developer apps.</li>
    <li><strong>Backfeed</strong>: I POSSE my posts out to the silos, but am able to pull likes and replies back into my site as comments. I do this using a brilliant service called <a href="https://www.brid.gy/">Bridgy</a> created by <a href="https://snarfed.org/">Ryan Barrett</a>.</li>
    <li><strong>PubSubHubbub</strong>: This pushes out my RSS feeds to major feed readers in near real-time.</li>
    <li><strong>Webmentions</strong>: This feature attempts to notify the various sites I link to. Webmentions are the technological successor to pingbacks and trackbacks, but pass more useful and readable information to the sites mentioned. My site can also accept webmentions, which can show up as comments.</li>
    <li><strong>URL shortener</strong>: I use HUM to create the <a href="http://j-f.me/">j-f.me</a> short URLs that show up on Twitter, Facebook, and Flickr.</li>
    <li><strong>IndieWeb Taxonomy</strong>: I don't do much with this yet, but it provides additional markup to indicate posts are replies, likes, reposts, or RSVPs.</li>
</ul>

As far as I can tell, Frank Chimero hasn't implemented many of these IndieWeb components, but he has moved more of his online identity to his personal site, which he discussed it in his post, <a href="http://frankchimero.com/blog/homesteading-2014/">Homesteading 2014</a>.

<blockquote>It seems the best way for me to do this is to step out of the stream and "build my own house," just like those architects. I don't have to simplify or crop or be pulled out of context (unless I want that), which hopefully produces a fuller picture of who I am, what I like, and what I value. I'm returning to a personal site, which flips everything on its head. Rather than teasing things apart into silos, I can fuse together different kinds of content. Instead of having fewer sections to attend to distracted and busy individuals, I'll add more (and hopefully introduce some friction, complexity, and depth) to reward those who want to invest their time.</blockquote>

I really like the idea of <a href="http://michaelbester.com/journal/online-homesteading">online Homesteading</a>. I'm building a place for myself. If anyone cares to follow along, great! If it's just me, that's okay too, because I'm building the website I want to visit.

With this foundation, I feel more comfortable signing up for other social networks and services as they come out. As long as there is a simple and convenient way to POSSE (Ello and Instagram have not done this yet), it doesn't add much complexity for me to get involved. It never hurts to have multiple copies of the data that is important to you. The stuff I make can live in many places. Really the more the better. As long as I own the original permalinks, then it really is mine.

If you're interested in taking control of your online identity, check out the IndieWeb <a href="http://indiewebcamp.com/Getting_Started">getting started guide</a>.
