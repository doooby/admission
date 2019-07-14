class UsersController < ApplicationController

  action_admission.before_action :enforce_user_presence
  action_admission.resource_for :edit, :update

  def new
    @user = User.new
  end

  def create
    @user = User.new user_params(:new)

    if @user.save
      flash[:notice] = "User #{@user.name} was created."
      redirect_to root_path

    else
      flash[:notice] = "Cannot create user: #{@user.errors.full_messages}"
      render :new

    end
  end

  def edit
  end

  def update
    if @user.update user_params(:edit)
      flash[:notice] = "User #{@user.name} was updated."
      redirect_to root_path

    else
      flash[:notice] = "Cannot update user: #{@user.errors.full_messages}"
      render :edit

    end
  end

  private

  def find_user
    @user = User.find params[:id]
  end

  def user_params action
    attrs = User.send "#{action}_attributes"
    params.require(:user).permit attrs.to_list
  end

end
