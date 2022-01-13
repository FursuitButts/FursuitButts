class UtilityShit
  def self.format_num(int)
    int.to_s.chars.to_a.reverse.each_slice(3).map(&:join).join(',').reverse
  end
end
