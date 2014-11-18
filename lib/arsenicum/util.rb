module Arsenicum
  module Util
    def self.included(base)
      mod = self
      base.module_eval{extend mod}
    end

    def normalize_hash(values)
      values.inject({}) do |h, kv|
        (key, value) = kv
        value = normalize_hash(value) if value.is_a? Hash
        h.tap{|i|i.merge!(key.to_sym => value)}
      end
    end

    def camelcase(stringlike, upcase_first = true)
      stringlike.to_s.dup.tap do |s|
        s.gsub!(/_([a-z])/){$1.upcase}
        s.gsub!(/^([a-z])/){$1.upcase} if upcase_first
      end.to_sym
    end

    def classify(stringlike)
      stringlike.split(/\/+/).map do |s|
        camelcase(s)
      end.join('::')
    end

    def underscore(stringlike)
      stringlike.to_s.dup.tap do |s|
        s.gsub!(/^([A-Z])/){$1.tap(&:downcase!)}
        s.gsub!(/([A-Z])/){'_' << $1.tap(&:downcase!)}
      end
    end

    def constantize(klass, inside: Kernel)
      if klass.to_s.start_with?('::')
        klass = klass.to_s[2..-1].to_sym
        inside = Kernel
      end
      klass.to_s.split('::').inject(inside) do |parent, const|
        parent.const_get const.to_sym
      end
    end

    extend self
  end
end
