require "sinatra" 
require "sinatra/reloader" if development?
require "tilt/erubis"
require "sinatra/content_for"

configure do 
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
end

helpers do 
  def list_complete?(list)
     list[:todos].size > 0 && list[:todos].all? {|todo| todo[:completed] == "true"}
  end

  def list_class(list)
    "complete" if list_complete?(list)
  end

  def todos_remaining_count(list)
    list[:todos].count {|todo| todo[:completed] == "true"}
  end

  def todos_count(list)
    list[:todos].size
  end

  def todo_complete?(todo)
    todo[:completed] == 'true'
  end

  def sort_lists(lists, &block)
    complete_lists, incomplete_lists = lists.partition { |list| list_complete?(list) }

    incomplete_lists.each(&block)
    complete_lists.each(&block)
  end

  def sort_todos(todos, &block)
    incomplete_todos = {}
    complete_todos = {}

    todos.each_with_index do |todo, index|
      if todo_complete?(todo)
        complete_todos[todo] = index 
      else
        incomplete_todos[todo] = index 
      end
    end

    incomplete_todos.each(&block)
    complete_todos.each(&block)
  end
end

before do 
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

# View list of lists
get "/lists" do
  @lists = session[:lists]
  erb :lists, layout: :layout
end

# Render the new list form
get "/lists/new" do 
  erb :new_list, layout: :layout
end

# Return an error message if the name is invalid. Return nil if name is valid
def error_for_list_name(name)
  if !(1..100).cover? name.size
    "List must be between 1 and 100 characters."
  elsif session[:lists].any? {|list| list[:name] == name}
    "List name must be unique."
  end
end

def error_for_todo(name)
  if !(1..100).cover? name.size
    "Todo name must be between 1 and 100 characters."
  end
end

# Create a new list
post "/lists" do 
  list_name = params[:list_name].strip

  if error = error_for_list_name(list_name)
    session[:error] = error
    erb :new_list, layout: :layout
  else
    session[:lists] << {name: list_name, todos: []}
    session[:success] = "The list has been created."
    redirect "/lists"
  end
end

# Display a single list
get "/lists/:number" do 
  @num = params[:number].to_i

  if @num > @lists.to_i 
    session[:error] = "The specified list was not found"
    redirect "/lists"
  end

  @this_list = session[:lists][@num]
  erb :temp_list_display, layout: :layout
end

#Render the edit list form
get "/lists/:num/edit" do
  @num = params[:number].to_i
  erb :edit_list, layout: :layout 
end

#Update the new name for the list
post "/lists/:num" do 
  @num = params[:number].to_i
  new_list_name = params[:new_list_name].strip

  if error = error_for_list_name(new_list_name)
    session[:error] = error
    redirect "/lists/#{@num}/edit"
  else
    session[:lists][@num][:name] = params[:new_list_name]
    session[:success] = "The list name has been updated."
    redirect "/lists/#{@num}"
  end
end

#Delete current list and redirect to main page
post "/lists/:num/delete" do 
  @num = params[:number].to_i
  session[:lists].delete_at(@num)
  session[:success] = "The list has been deleted"
  redirect "/"
end

#Add a new todo to a list 
post "/lists/:num/todos" do 
  @num = params[:num].to_i
  @this_list = session[:lists][@num]
  text = params[:todo].strip

  if error = error_for_todo(text)
    session[:error] = error
    erb :temp_list_display, layout: :layout
  else
    @this_list[:todos] << {name: text, completed: "false"}
    session[:success] = "The todo has successfully been added."
    redirect "/lists/#{@num}"
  end
end

#Delete a todo from a list
post "/lists/:num/delete/:index" do 
  @num = params[:num].to_i
  @index = params[:index].to_i
  session[:lists][@num][:todos].delete_at(@index)
  session[:success] = "The todo has successfully been deleted."
  redirect "/lists/#{@num}"
end

#Mark a todo as completed
post "/lists/:num/todo/:index" do 
  @num = params[:num].to_i
  @index = params[:index].to_i
  @list = session[:lists][@num]
  todo = @list[:todos][@index]
  @list[:todos][@index][:completed] = params[:completed]

  redirect "/lists/#{@num}"
end

post "/lists/:num/complete_all" do 
  @num = params[:num].to_i
  session[:lists][@num][:todos].each do |todo|
    todo[:completed] = "true"
  end
  session[:success] = "All todos have been completed"
  redirect "lists/#{@num}"
end






