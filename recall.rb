require 'sinatra'
require 'data_mapper'
require 'rack-flash'
require 'sinatra/redirect_with_flash'

SITE_TITLE = "Recall"
SITE_DESCRIPTION = "A note taking app"

enable :sessions  
use Rack::Flash, :sweep => true
#------------------------------------------------------------------------------#
# Sets up a new SQLite3 database for recall
DataMapper::setup(:default, "sqlite3://#{Dir.pwd}/recall.db")

# Datamapper creates a table Notes
# class note has 5 fields:
#1. 'id' - a int primary key that auto-increments
#2. 'content' - containts the text, which if true means that text has been entered
#3. 'complete' - if note is completed then true
#4. 'created_at' - time when note was created
#5. 'updated_at' - time when note was updated

class Note
	include DataMapper::Resource
	property :id, Serial
	property :content, Text, :required => true
	property :complete, Boolean, :required => true, :default => 0
	property :created_at, DateTime
	property :updated_at, DateTime
end

DataMapper.auto_upgrade!
##----------------------------------------------------------------------------##
# Converts user-side submitted code into html entities; prevents XSS attacks
helpers do  
        include Rack::Utils  
        alias_method :h, :escape_html  
    end  
#------------------------------------------------------------------------------#
# @notes retrieves notes from the database and assigns the notes to itself
# @title sets the title
# erb :home summons home.erb which contains part of the html code
get '/' do
	@notes = Note.all :order => :id.desc
	@title = 'All Notes'
	if @notes.empty?
	  flash[:error] = "No notes found. Please add one below."
	end
	erb :home
end
#------------------------------------------------------------------------------#
# n = note object, and is created when ever a post request is made
# content takes the submitted data
# created_at and updated_at are set to the current time
# saves the note and then redirects to the homepage
post '/' do  
        n = Note.new  
        n.content = params[:content]  
        n.created_at = Time.now  
        n.updated_at = Time.now  
        if n.save  
            redirect '/', :notice => 'Note created successfully.'  
        else  
            redirect '/', :error => 'Failed to save note.'  
        end  
    end  
#------------------------------------------------------------------------------#
# Allows the user to edit notes
get '/:id' do  
        @note = Note.get params[:id]  
        @title = "Edit note ##{params[:id]}"  
        if @note  
            erb :edit  
        else  
            redirect '/', :error => "Can't find that note."  
        end  
    end  
##----------------------------------------------------------------------------##
# RSS feed; requests all the notes in the database while loading a rss viwe file
get '.rss.xml' do
  @notes = Note.all :order => :id.desc
  builder :rss
end

get '/:id' do
	@note = Note.get params[:id]
	@title = "Edit note ##{params[:id]}"
	if @note
		erb :edit
	else
		redirect '/', :error => "Can't find that note."
	end
end

#------------------------------------------------------------------------------#
# Creates a route by:
# geting the notes id int from the URI
# sets the content, complete, and updated_at to currect values
# saves then redirects back to the homepage
put '/:id' do
n = Note.get params[:id]  
    unless n  
        redirect '/', :error => "Can't find that note."  
    end  
    n.content = params[:content]  
    n.complete = params[:complete] ? 1 : 0  
    n.updated_at = Time.now  
    if n.save  
        redirect '/', :notice => 'Note updated successfully.' 
    else 
        redirect '/', :error => 'Error updating note.'  
    end  
end  
#------------------------------------------------------------------------------#
#The 'delete route'
get '/:id/delete' do  
        @note = Note.get params[:id]  
        @title = "Confirm deletion of note ##{params[:id]}"  
        if @note  
            erb :edit  
        else  
            redirect '/', :error => "Can't find that note."  
        end  
    end
#------------------------------------------------------------------------------#

delete '/:id' do  
        n = Note.get params[:id]  
        if n.destroy  
            redirect '/', :notice => 'Note deleted successfully.'  
        else  
            redirect '/', :error => 'Error deleting note.'  
        end  
    end  
#------------------------------------------------------------------------------#
# Sets a note as completed
# gets the notes id, sets complete to true
# gets update time, saves, then redirects to the homepage
get '/:id/complete' do
	n = Note.get params[:id]
	n.complete = n.complete ? 0 : 1 # flip it
	n.updated_at = Time.now
	n.save
	redirect '/'
end


