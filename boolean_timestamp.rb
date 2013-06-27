# Model must include an activated_at datetime field
# Usage in AR Model
#   boolean_timestamp :activate
#
# Gives the following instance methods:
#   - activated
#   - activated=
#   - activated?
#   - activate!
#
# Gives the following scope
#   scope :activated, where("activated_at IS NOT NULL")

module ActiveRecord
  module BooleanTimestamp
    extend ActiveSupport::Concern
    
    module ClassMethods
      def boolean_timestamp(name, passive_name=nil)
        active_name      = name.to_s.strip.downcase
        passive_name   ||= passive_name(active_name)
        attribute_name   = passive_name + "_at"
        
        action_method(active_name, passive_name)
        reader_method(passive_name, attribute_name)
        writer_method(passive_name, attribute_name)
        question_method(passive_name)
        add_scopes(passive_name, attribute_name)
        
        # Could offer the inverse like deactivated, unconfirmed, etc.
      end
      
      private
        def passive_name(active_name)
          return active_name[0..-2] + "ied" if active_name.end_with?("y")
          return active_name        + "d"   if active_name.end_with?("e")
          
          active_name + "ed"
        end
      
        def action_method(active_name, passive_name)
          define_method("#{active_name}!") do
            self.update_attribute(passive_name, true)
          end
        end
        
        def reader_method(passive_name, attribute_name)
          define_method("#{passive_name}") do
            self.send("#{attribute_name}?")
          end
        end

        def writer_method(passive_name, attribute_name)
          define_method("#{passive_name}=") do |value|
            is_true = value.to_s.strip =~ /^1|y.*|t.*$/i
            
            return if is_true && self.send("#{passive_name}?")
            
            self.send("#{attribute_name}=", is_true ? Time.now : nil)
          end
        end
        
        def question_method(passive_name)
          define_method("#{passive_name}?") do
            self.send(passive_name)
          end
        end
        
        def add_scopes(passive_name, attribute_name)
          scope passive_name, where("#{attribute_name} IS NOT NULL")
        end
    end
  end
end


module ActiveRecord
  class Base
    include BooleanTimestamp
  end
end