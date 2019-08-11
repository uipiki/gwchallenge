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


  def initialize(point_status, stage_count, deposit, existing_total, others_top_point)
    @finish_type = {tumo: "tumo", ron: "ron"}
    @child_deagari_points = [1000, 1300, 1600, 2000, 2300,
                             2600, 3200, 3900, 4500, 5200, 6400, 8000, 12000, 16000, 24000, 32000]
    @child_tumo_points = [{ko: 300, oya: 500}, {ko: 400, oya: 700},
                          {ko: 500, oya: 1000}, {ko: 600, oya: 1200}, {ko: 700, oya: 1300},
                          {ko: 800, oya: 1600}, {ko: 1000, oya: 2000}, {ko: 1200, oya: 2300},
                          {ko: 1300, oya: 2600}, {ko: 1600, oya: 3200}, {ko: 2000, oya: 4000},
                          {ko: 3000, oya: 6000}, {ko: 6000, oya: 12000}, {ko: 8000, oya: 16000}]
    @oya_deagari_points = [1500, 2000, 2400, 2900, 3400, 4800, 5800, 6800, 7700, 9600, 12000, 18000, 24000, 36000, 48000]
    @oya_tumo_points = [500, 700, 800, 1000, 1200, 1300, 1600, 2000, 2300, 2600, 3200, 4000, 6000, 8000, 12000, 16000]
    @point_status = point_status
    @stage_count = stage_count.to_i
    @deposit = deposit.to_i
    @existing_total = existing_total
    @others_top_point = others_top_point.to_i
  end


  def require_conditions
    ron_conditions = {}
    tumo_conditions = {}
    @point_status.each do |wind_type, point|
      ron_conditions[wind_type] = get_ron_condition(wind_type, @point_status, @deposit, @stage_count, @existing_total)
      tumo_conditions[wind_type] = get_tumo_condition(wind_type, @point_status, @deposit, @stage_count, @existing_total)
    end
    noten_condition = get_ryukyoku_condition(@point_status, @deposit, @existing_total)
    return {
        ron: ron_conditions,
        tumo: tumo_conditions,
        ryukyoku: noten_condition
    }
  end

  # 伏せられるかの条件(親のみ)
  def get_ryukyoku_condition(point_status, deposit, existing_total)
    result = {}
    noten_result = hitori_noten_calc(:ton, point_status, deposit)
    if totaltop?(:ton, noten_result, existing_total)
      result[:hitori_noten] = noten_result
      result[:hitori_noten][:game_point] = calc_uma_oka(noten_result)
    end
    futari_noten_results = futari_noten_calc(:ton, point_status, deposit)
    futari_noten_results.each do |noten_wind, game_result|
      if totaltop?(:ton, game_result, existing_total)
        unless result[:futari_noten].present?
          result[:futari_noten] = {}
        end
        result[:futari_noten][noten_wind] = game_result
        result[:futari_noten][noten_wind][:game_point] = calc_uma_oka(game_result)
      end
    end
    hitori_tenpai_results = hitori_tenpai_calc(:ton, point_status, deposit)
    hitori_tenpai_results.each do |tenpai_wind, game_result|
      if totaltop?(:ton, game_result, existing_total)
        unless result[:hitori_tenpai].present?
          result[:hitori_tenpai] = {}
        end
        result[:hitori_tenpai][tenpai_wind] = game_result
        result[:hitori_tenpai][tenpai_wind][:game_point] = calc_uma_oka(game_result)
      end
    end
    return result
  end

  def hitori_tenpai_calc(wind, status, deposit)
    tenpai_results = {}
    tenpai_result = {}
    [:nan, :sya, :pe].each do |tenpai_wind|
      status.each do |calced_wind, point|
        if tenpai_wind == calced_wind
          tenpai_result[calced_wind] = point + 3000
        else
          tenpai_result[calced_wind] = point - 1000
        end
      end
      tenpai_results[tenpai_wind] = distribute_deposit(tenpai_result, deposit)
    end
    return tenpai_results
  end

  def futari_noten_calc(wind, status, deposit)
    noten_results = {}
    noten_result = {}
    [:nan, :sya, :pe].each do |noten_wind|
      status.each do |calced_wind, point|
        if wind == calced_wind || noten_wind == calced_wind
          noten_result[calced_wind] = point - 1500
        else
          noten_result[calced_wind] = point + 1500
        end
      end
      noten_results[noten_wind] = distribute_deposit(noten_result, deposit)
    end
    return noten_results
  end

  def hitori_noten_calc(wind, status, deposit)
    noten_result = {}
    status.each do |calcled_wind, point|
      if wind == calcled_wind
        noten_result[calcled_wind] = point - 3000
      else
        noten_result[calcled_wind] = point + 1000
      end
    end
    result = distribute_deposit(noten_result, deposit)
    return result
  end

  def distribute_deposit(noten_result, deposit)
    result = {}
    noten_result.each do |result_wind, result_point|
      rank = noten_result.values.sort.reverse.index(result_point)
      same_rank = noten_result.values.count(result_point)
      if rank == 0
        result[result_wind] = result_point + split_deposit(result_wind, same_rank, deposit)
      else
        result[result_wind] = result_point
      end
    end
    return result
  end

  def split_deposit(wind, same_rank, deposit)
    if same_rank == 1
      return deposit
    end
    if same_rank == 2
      return deposit / 2.to_d
    end
    if same_rank == 3
      if deposit % 3 == 0
        return deposit / 3.to_d
      end
      if wind == :nan
        return (deposit - deposit / 100 / 3.floor * 100 * 2).to_d
      else
        return (deposit / 100 / 3.floor * 100).to_d
      end
    end
  end

  #
  # ツモの時の条件を返す
  #
  def get_tumo_condition(wind, status, deposit, stage_count, existing_total)
    hand_points = get_hand_points(wind, @finish_type[:tumo])
    if parent?(wind.to_s)
      hand_points.each do |point|
        move_point = point + stage_count * 100
        tumoed_status = tumo_by_parent(status, move_point, deposit)
        if totaltop?(wind, tumoed_status, existing_total)
          result = {}
          result[:message] = point.to_s + " all"
          result[:status] = tumoed_status
          result[:game_point] = calc_uma_oka(tumoed_status)
          return result
          break
        end
      end
    else
      hand_points.each do |point_hash|
        tumoed_status = tumo_by_child(wind, status, stage_count, deposit, point_hash)
        if totaltop?(wind, tumoed_status, existing_total)
          result = {}
          result[:message] = point_hash[:ko].to_s + "-" + point_hash[:oya].to_s
          result[:status] = tumoed_status
          result[:game_point] = calc_uma_oka(tumoed_status)
          return result
          break
        end
      end
    end
    return {}
  end

  def tumo_by_parent(status, move_point, deposit)
    result = {}
    status.each do |wind, point|
      if parent?(wind.to_s)
        result[wind] = status[:ton] + deposit + move_point * 3
      else
        result[wind] = status[wind] - move_point
      end
    end
    return result
  end

  def tumo_by_child(wind, status, stage_count, deposit, point_hash)
    result = {}
    status.each do |others_wind, point|
      if others_wind == wind
        result[others_wind] = status[wind] + deposit + point_hash[:ko] * 2 + point_hash[:oya] + stage_count * 300
        next
      end
      if parent?(others_wind.to_s)
        result[others_wind] = status[others_wind] - point_hash[:oya] - stage_count * 100
      else
        result[others_wind] = status[others_wind] - point_hash[:ko] - stage_count * 100
      end
    end
    return result
  end

  #
  # ロンの時の条件を返す
  # @param [String] wind 自風
  # @param [Integer] status 状況
  # @param [Integer] deposit 供託
  # @param [Integer] stage_count 本場
  # @param [Map<String, Map<String, Integer>>] 上がる前のトータルポイント状況
  #
  def get_ron_condition(wind, status, deposit, stage_count, exisiting_total)
    hand_points = get_hand_points(wind, @finish_type[:ron])
    result = {}
    conditions = {}
    conditionss = {}
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
          conditions[others_wind] = point
          conditionss[others_wind] = {}
          conditionss[others_wind][:point] = point
          conditionss[others_wind][:status] = ronned_status
          conditionss[others_wind][:game_point] = calc_uma_oka(ronned_status)
          break
        end
      end
    end
    result[wind] = conditionss
  end


  def after_ron_status(wind, others_wind, status, move_point, deposit)
    result = {}
    my_point = status[wind] + move_point + deposit
    others_point = status[others_wind] - move_point
    status.each do |k, v|
      if k == wind
        result[k] = my_point
      elsif k == others_wind
        result[k] = others_point
      else
        result[k] = v
      end
    end
    return result
  end

  def totaltop?(wind, current_status, existing_total)
    game_point = calc_uma_oka(current_status)
    finished_total = sum_point(game_point, existing_total)
    return is_top?(wind, finished_total)
  end

  def calc_uma_oka(ronned_status)
    result = {}
    ronned_status.each do |wind, point|
      umaoka = get_uma_oka(wind, ronned_status)
      result[wind] = (point - 30000 + umaoka) / 1000.to_d
    end
    return result
  end

  def sum_point(game_point, existing_total)
    result = {}
    game_point.each do |wind, point|
      result[wind] = point + existing_total[wind]
    end
    return result
  end

  # パラメタの風がトップかどうか返す
  # @param [String] wind
  # @param [Hash<String, Integer>] finished_total
  def is_top?(wind, finished_total)
    my_point = finished_total[wind]
    rank = finished_total.values.sort.reverse.index(my_point)
    if rank == 0 and my_point > @others_top_point
      return true
    end
    return false
  end

  # ウマオカを返す
  # @param [String] wind
  # @param [Map<String, Integer>] ronned_status
  def get_uma_oka(wind, ronned_status)
    my_point = ronned_status[wind]
    points = ronned_status.values
    sorted_point = points.sort.reverse
    rank = sorted_point.index(my_point) + 1
    duplicates = points.group_by(&:itself).map {|k, v| [k, v.count]}.to_h[my_point]
    umaoka_point = umaoka(rank, duplicates)

    return umaoka_point
  end

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
    if parent?(wind.to_s)
      if finish_type == @finish_type[:ron]
        return @oya_deagari_points
      else
        return @oya_tumo_points
      end
    else
      if finish_type == @finish_type[:ron]
        return @child_deagari_points
      else
        return @child_tumo_points
      end
    end
  end

  def parent?(wind)
    return wind == "ton"
  end

  def to_parent_tumo_message_string(point, wind)
    if parent?(wind)
      return point.to_s + " all"
    end
  end
end