class ConditionController < ApplicationController

  def index
  end

  def calc
    p params
    render json: {success: params} and return
  end
end