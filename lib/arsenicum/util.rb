module Arsenicum
  module Util
    def normalize_hash(values)
      values.inject({}) do |h, kv|
        (key, value) = kv
        value = normalize_hash(value) if value.is_a? Hash
        h.tap{|i|i.merge!(key.to_sym => value)}
      end
    end

    def camelcase(stringlike, upcase_first = true)
      stringlike.to_s.tap do |s|
        s.gsub!(/_([a-z])/){$1.upcase}
        s.gsub!(/^([a-z])/){$1.upcase} if upcase_first
      end.to_sym
    end
  end
end