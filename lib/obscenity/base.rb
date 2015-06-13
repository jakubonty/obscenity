module Obscenity
  class Base
    class << self

      def locale_blacklist
        return @locale_blacklist if @locale_blacklist
        @locale_blacklist = {}
        if Obscenity.config.locale_blacklist
          Obscenity.config.locale_blacklist.each do |locale, file|
            @locale_blacklist[locale] = YAML.load_file( file.to_s )
          end
        end
        @locale_blacklist
      end

      def blacklist(locale=nil)
        @blacklist ||= set_list_content(Obscenity.config.blacklist)
        if locale
          return locale_blacklist[locale] || @blacklist
        end
        @blacklist
      end

      def blacklist=(value)
        @blacklist = value == :default ? set_list_content(Obscenity::Config.new.blacklist) : value
      end

      def whitelist
        @whitelist ||= set_list_content(Obscenity.config.whitelist)
      end

      def whitelist=(value, locale)
        @whitelist = value == :default ? set_list_content(Obscenity::Config.new.whitelist) : value
      end

      def profane?(text, locale=nil)
        return(false) unless text.to_s.size >= 3
        blacklist(locale).each do |foul|
          return(true) if text =~ /\b#{foul}\b/i && !whitelist.include?(foul)
        end
        false
      end

      def sanitize(text, locale=nil)
        return(text) unless text.to_s.size >= 3
        blacklist(locale).each do |foul|
          text.gsub!(/\b#{foul}\b/i, replace(foul)) unless whitelist.include?(foul)
        end
        @scoped_replacement = nil
        text
      end

      def replacement(chars)
        @scoped_replacement = chars
        self
      end

      def offensive(text, locale)
        words = []
        return(words) unless text.to_s.size >= 3
        blacklist(locale).each do |foul|
          words << foul if text =~ /\b#{foul}\b/i && !whitelist.include?(foul)
        end
        words.uniq
      end

      def replace(word)
        content = @scoped_replacement || Obscenity.config.replacement
        case content
        when :vowels then word.gsub(/[aeiou]/i, '*')
        when :stars  then '*' * word.size
        when :nonconsonants then word.gsub(/[^bcdfghjklmnpqrstvwxyz]/i, '*')
        when :default, :garbled then '$@!#%'
        else content
        end
      end

      private
      def set_list_content(list)
        case list
        when Array then list
        when String, Pathname then YAML.load_file( list.to_s )
        else []
        end
      end

    end
  end
end
