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
                                               params[:stage_count],
                                               params[:deposit],
                                               existing_total,
                                               params[:others_top_point])
    @condition = calclatour.require_conditions
    @point_status = point_status
    @existing_total = existing_total
    render 'condition/condition'
  end

  private

  def to_mahjong_hash(ton, nan, sya, pe)
    result = {ton: ton.to_i, nan: nan.to_i, sya: sya.to_i, pe: pe.to_i}
    return result
  end
end