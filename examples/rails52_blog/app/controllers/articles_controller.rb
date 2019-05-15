class ArticlesController < ApplicationController

  action_admission.before_action :enforce_user_presence
  action_admission.resource_for :show, :edit, :update
  action_admission.for :create_message, resolve_to: :messages_scope

  def show
  end

  def new
    @article = Article.new author: current_user
  end

  def create
    @article = Article.new article_attributes.merge(author: current_user)

    if @article.save
      flash[:notice] = "Article #{@article.title} was created."
      redirect_to root_path

    else
      flash[:notice] = "Cannot create article: #{@article.errors.full_messages}"
      render :new

    end
  end

  def edit
  end

  def update
    if @article.update article_attributes
      flash[:notice] = "Article #{@article.title} was updated."
      redirect_to root_path

    else
      flash[:notice] = "Cannot update article: #{@article.errors.full_messages}"
      render :edit

    end
  end

  def create_message
    @message = Message.new user: current_user,
        article: @article,
        body: params[:body].presence
    @message.save! if @message.body
    redirect_to article_path(@article)
  end

  private

  def find_article
    @article = Article.find params[:id]
  end

  def article_attributes
    attrs = {}

    title = params[:title]
    attrs[:title] = title if title

    body = params[:body]
    attrs[:body] = body.gsub /(\s*\n)+/, ';' if body

    attrs
  end

  def messages_scope
    [find_article, :messages]
  end

end
