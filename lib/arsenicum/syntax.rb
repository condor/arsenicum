module Arsenicum
  module Syntax
    autoload :DelayedJob, 'arsenicum/syntax/delayed_job'

    def self.choose(syntax)
      syntax_impl =
        const_get syntax.to_s.gsub(/_([a-z])/){$1.upcase}.gsub(/^([a-z])/){$1.upcase}.to_sym
      syntax_impl.enable!
    end
  end
end
