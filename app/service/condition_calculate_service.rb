#
# 順位点
# +50000 +10000 -10000 -30000
# 現時点の自分のポイント
# 現時点の全員の名前とポイントのマッピング
# だれが親か
# 本場
# 供託
# 全チームの名前とポイントのマッピング
#

class ConditionCalculateService

  enum finish_type: {tumo: "tumo", ron: "ron"}

  def init(point_status, stage_count, deposit, existing_total, others_top_point)
    @child_deagari_points = [1000, 1300, 1600, 2000, 2300,
                             2600, 3200, 3900, 4500, 5200, 6400, 8000, 12000, 16000, 24000, 320000]
    ​
    @child_tumo_points = [{ko: 300, oya: 500}, {ko: 400, oya: 700},
                          {ko: 500, oya: 1000}, {ko: 600, oya: 1200}, {ko: 700, oya: 1300},
                          {ko: 800, oya: 1600}, {ko: 1000, oya: 2000}, {ko: 1200, oya: 2300},
                          {ko: 1300, oya: 2600}, {ko: 1600, oya: 3200}, {ko: 2000, oya: 4000},
                          {ko: 3000, oya: 6000}, {ko: 6000, oya: 12000}, {ko: 8000, oya: 16000}]
    ​
    @oya_deagari_points = [1500, 2000, 2400, 2900, 3400, 4800, 5800, 6800, 7700, 9600, 12000, 18000, 24000, 36000, 48000]
    @oya_tumo_points = [500, 700, 800, 1000, 1200, 1300, 1600, 2000, 2300, 2600, 3200, 4000, 6000, 8000, 12000, 16000]
    @point_status = point_status
    @stage_count = stage_count
    @deposit = deposit
    @existing_total = existing_total
    @others_top_point = others_top_point
  end


  def require_conditions
    @point_status.each do |wind_type, point|
      get_ron_condition(wind_type, @point_status, @deposit, @stage_count, @exisiting_total)
      get_tumo_condition(wind_type, @point_status, @deposit, @stage_count, @exisiting_total)
    end
  end

  ​
#
# ツモの時の条件を返す
#
  def get_tumo_condition(wind, status, deposit, stage_count, exisiting_total)
    hand_points = get_hand_points(wind, finish_types.tumo)
    if parent?(wind)
      hand_points.each do |point|
        move_point = point + stage_count * 100
        tumoed_status = tumo_by_parent(status, move_point, deposit)
        if totaltop?(wind, tumoed_status, exisiting_total)
          write_message(wind, others_wind, point, finish_types.tumo)
          break
        end
      end
    else
      hand_points.each do |point_hash|
        tumoed_status = tumo_by_child(wind, status, stage_count, deposit, point_hash)
        if totaltop?(wind, tumoed_status, exisiting_total)
          write_message(wind, others_wind, point, FINISH_TYPE::TUMO)
          break
        end
      end
    end
  end

  ​

  def tumo_by_parent(status, move_point, deposit)
    result = {}
    status.each do |wind, point|
      if parent?(wind)
        result[wind] = status["ton"] + deposit + move_point * 3
      else
        result[wind] = status[wind] - move_point
      end
    end
    return result
  end

  ​

  def tumo_by_child(wind, status, stage_count, deposit, point_hash)
    result = {}
    status.each do |others_wind, point|
      if others_wind == wind
        result[others_wind] = status[wind] + deposit + point_hash[:ko] * 2 + point_hash[:oya] + stage_count * 300
        next
      end
      if parent?(others_wind)
        result[others_wind] = status[others_point] - point_hash[:oya] - stage_count * 100
      else
        result[others_wind] = status[others_point] - point_hash[:ko] - stage_count * 100
      end
    end
    return result
  end

  ​
#
# ロンの時の条件を返す
# @param [String] wind 自風
# @param [Integer] status 状況
# @param [Integer] deposit 供託
# @param [Integer] stage_count 本場
# @param [Map] 上がる前のトータルポイント状況
#
  def get_ron_condition(wind, status, deposit, stage_count, exisiting_total)
    hand_points = get_hand_points(wind, finish_types.ron)
    # 他家の出上がり条件探すためのループ
    status.each do |others_wind, others_point|
      # 自分にロンはできないので次へ
      if wind == others_wind
        next
      end
      hand_points.each do |point|
        # で上がり点は素点＋本場分の点
        move_point = point + (300 * stage_count)
        ronned_status = after_ron_status(wind, others_wind, status, move_point, deposit)
        if totaltop?(wind, ronned_status, exisiting_total)
          write_message(wind, others_wind, point, type)
        end
      end
    end
  end

  ​

  def write_message(wind, others_wind, point, type)
  end

  ​

  def after_ron_status(wind, others_wind, status, move_point, deposit)
    my_point = status[wind] + move_point + deposit
    status[wind] = my_point
    others_point = status[others_point] - move_point
    status[others_point] = others_point
    return status
  end

  ​

  def totaltop?(wind, ronned_status, exisiting_total)
    game_point = calc_uma_oka(ronned_status)
    finished_total = sum_point(game_point, exisiting_total)
    return is_top?(wind, finished_total)
  end

  ​

  def calc_uma_oka(ronned_status)
    result = {}
    ronned_status.each do |wind, point|
      umaoka = get_uma_oka(wind, ronned_status)
      result[wind] = (point + umaoka) / 100
    end
    return result
  end

  ​

  def sum_point(game_point, exisiting_total)
    result = {}
    game_point.each do |wind, point|
      result[wind] = point + exisiting_total[wind]
    end
    return result
  end

  ​
# パラメタの風がトップかどうか返す
# @param [String] wind
# @param [Hash<String, Integer>] finished_total
  def is_top?(wind, finished_total)
    my_point = finished_total[wind]
    rank = finished_total.values.sort.index(my_point)
    if rank == 0 and my_point > @others_table_top_point
      return true
    end
    return false
  end

  ​
# ウマオカを返す
# @param [String] wind
# @param [Map<String, Integer>] ronned_status
  def get_uma_oka(wind, ronned_status)
    my_point = ronned_status[wind]
    points = ronned_status.values
    sorted_point = points.sort
    rank = sorted_point.index(my_point)
    duplicates = points.group_by(&:itself).map {|k, v| [k, v.count]}.to_h[my_point]
    umaoka_point = umaoka(rank, duplicates)
    return umaoka_point
  end

  ​

  def umaoka(rank, dupulicated_rank_num)
    if rank == 1
      if dupulicated_rank_num == 4
        return 5000
      elsif dupulicated_rank_num == 3
        return 50000 / 3
      elsif dupulicated_rank_num == 2
        return 30000
      elsif dupulicated_rank_num == 1
        return 50000
      end
    elsif rank == 2
      if dupulicated_rank_num == 3
        return -10000
      elsif dupulicated_rank_num == 2
        return 0
      elsif dupulicated_rank_num == 1
        return 10000
      end
    elsif rank == 3
      if dupulicated_rank_num == 2
        return -20000
      elsif dupulicated_rank_num == 1
        return -10000
      end
    elsif rank == 4
      return -30000
    end
  end

#
# 出上がりのリストを返します。
# @return [Array[Integer]]
#
  def get_hand_points(wind, finish_type)
    if parent?(wind)
      if finish_type == finish_types.ron
        return @oya_deagari_points
      else
        return @oya_tumo_points
      end
    else
      if finish_type == finish_types.ron
        return @child_deagari_points
      else
        return @child_tumo_points
      end
    end
  end

  ​

  def parent?(wind)
    return wind == "ton"
  end

end