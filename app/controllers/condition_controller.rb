class ConditionController < ApplicationController

  def information
  end

  def calc
    point_status = to_mahjong_hash(params[:ton_point],
                                   params[:nan_point],
                                   params[:sya_point],
                                   params[:pe_point])
    existing_total = to_mahjong_hash(params[:ton_total],
                                   params[:nan_total],
                                   params[:sya_total],
                                   params[:pe_total])
    calclatour = ConditionCalculateService.new(point_status,
                                               existing_total,
                                               params[:stage_count],
                                               params[:deposit],
                                               params[:others_top_point])
    # calclatour.require_conditions
    # render json: {success: params} and return
    render 'condition/condition'
  end

  private

  def to_mahjong_hash(ton, nan, sya, pe)
    result = {ton: ton, nan: nan, sya: sya, pe: pe}
    return result
  end
end