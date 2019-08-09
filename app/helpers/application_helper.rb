module ApplicationHelper

  def to_caption(wind)
    case wind.to_s
    when "ton"
      return "東"
    when "nan"
      return "南"
    when "sya"
      return "西"
    when "pe"
      return "北"
    end
  end
end
