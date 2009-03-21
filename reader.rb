require 'rubygems'
require 'sinatra'
require 'sequel'
require 'open-uri'
require 'rss/1.0'
require 'rss/2.0'
require 'rfeedfinder'

configure do
	DB = Sequel.connect('sqlite://reader.db')
	if !DB.table_exists?('feeds')
		DB.create_table :feeds do
			primary_key :id
			text :name, :null => false
			text :feed_url, :null => false
		end
	end
end

# just a simple model for the feeds table
class Feed < Sequel::Model; end

before do
	@title = "My feeds as of: #{DateTime::now().to_s}"
end

get '/?' do
	redirect '/feeds' # just 'cuz
end

get '/feeds' do
	@feeds = get_feedlist
	erb :index
end

get '/feeds/:id' do |feed_id|
	@feeds = get_feedlist
	f = Feed[:id => feed_id]
	@rss = get_feed(f.feed_url)
	erb :index
end

post '/feeds' do
	url = Rfeedfinder.feed(params[:site]) # 
	rss = get_feed(url)
	@name = rss.channel.title
	feed = Feed.create(:name => @name, :feed_url => url)
	redirect '/feeds/' + feed.id.to_s
end

delete '/feeds/:id' do |feed_id|
	Feed[:id => feed_id].delete
	redirect '/feeds'
end

helpers do
	def get_feedlist
		Feed.order(:name)
	end
	def get_feed(feed_url)
		content = nil
		open(feed_url) do |s| content = s.read end
		RSS::Parser.parse(content, false)
	end
end

__END__

@@ index
<table id="reader" cellpadding="0" cellspacing="0" border="0">
<tr>
<td id="feeds">
<%=erb(:feedlist, :layout => false) %>
</td>
<td id="articles">
<%=erb(:articles, :layout => false) %>
</td>
</tr>
</table>

@@ feedlist
<ol id="feedlist">
<% @feeds.each do |f| %>
<li><a href="/feeds/<%=f.id%>"><%=f.name%></a>
<a class="del" href="/feeds/<%= f.id %>" onclick="return false;">[X]</a></li>
<% end %>
</ol>

@@ articles
<%if @rss  %>
<h3><%=@rss.channel.title%></h3>
<ol class="feed">
<% @rss.items.each do |i| %>
<li class="link">
<h3 class="title"><%=i.title%></h3>
<div class="desc"><a href="<%= i.link %>" target="_blank"></a>
<%= i.description %></div>
</li>
<% end %>
</ol>
<% end %>

