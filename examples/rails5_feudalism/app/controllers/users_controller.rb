class UsersController < ApplicationController

  before_action :set_user, only: %i[show edit update destroy]
  before_action :prepare_privilege_params!, only: %i[create update]

  def index
    @users = User.all
  end

  def show
  end

  def new
    @user = User.new
  end

  def edit
  end

  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to @user, notice: 'User was successfully created.'
    else
      render :new
    end
  end

  def update
    if @user.update(user_params)
      redirect_to @user, notice: 'User was successfully updated.'
    else
      render :edit
    end
  end

  def destroy
    @user.destroy
    redirect_to users_url, notice: 'User was successfully destroyed.'
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def user_params
    params.fetch(:user, {}).permit privileges: {}
  end

  def prepare_privilege_params!
    return unless params[:user]

    privileges = params[:user][:privileges]
    unless privileges
      params[:user][:privileges] = nil
      return
    end

    countries = (privileges[:country].presence || [])
    names = privileges[:name].presence || []

    list = countries.zip(names).map do |country, name|
      name, level = name.split '-'
      UserStatus.privilege_for_country name, level.presence, country
    end

    params[:user][:privileges] = UserStatus.dump_privileges list.compact
    params[:user][:privileges].permit!
  end

end
