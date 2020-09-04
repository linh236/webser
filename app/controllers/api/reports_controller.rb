module Api
  class ReportsController < ApplicationController
    skip_before_action :authenticate_user!
    skip_before_action :verify_authenticity_token
    before_action :set_params, only: [:show, :destroy]

    def index
      @reports = Report.where(user_id: current_user.id)
      render json: {data: @reports}
    end
    def show
      render json: {data: @report}
    end

    def showpopup
      @reports = Report.where(information_id:params[:id]).order("created_at DESC")
      render json: {data: @reports}
    end
    def create
      title = params[:title]
      content = params[:content]
      information_id = params[:information_id]
      room = Room.find_by_information_id(information_id)
      user = User.where(house_id: room.house_id, admin: 1)
      user.each do |u|
        report = Report.new(title: title, content: content, information_id: information_id, user_id: u.id)
        if report.save
          render json: {status: 200}
        else
          render json: {status: report.errors}
        end
      end
    end

    def destroy
      @report.destroy
      render json: {status: 200}
    end
    private

    def set_params
      @report = Report.find(params[:id])
    end
  end
end