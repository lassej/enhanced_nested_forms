

class ActiveRecord::Base

  IMAGE_INPUT_COORDINATES_REGEXP = /^(.*)\.([xy])$/

  def attributes_with_coordinates_filter=( attrs)
    result  = attrs.dup
    coords = attrs.keys.select { |k| k.to_s.match( IMAGE_INPUT_COORDINATES_REGEXP) }
    coords.each do |coord|
      key, c = coord.to_s.match( IMAGE_INPUT_COORDINATES_REGEXP)[1..2]
      if ! attrs.keys.include?( key)
        result[key] = "1"
      end
      result["#{key}_#{c}"] = attrs[coord]
    end
    self.attributes_without_coordinates_filter=( result.reject { |k, v| k.to_s.match( IMAGE_INPUT_COORDINATES_REGEXP) } )
  end
  alias_method_chain :attributes=, :coordinates_filter unless method_defined?( :attributes_without_coordinates_filter=)

  def self.accepts_nested_attributes_for_with_add_association( *attr_names)
    result = accepts_nested_attributes_for_without_add_association( *attr_names)

    association_names = attr_names.select { |attr_name| ! attr_name.is_a?( Hash) }

    association_names.each do |association_name|
      case self.reflect_on_association(association_name.to_sym).macro
      when :has_one, :belongs_to
        class_eval %{
          def build_#{association_name}_from_nested_attributes
            self.build_#{association_name}
          end
        }
      when :has_many, :has_and_belongs_to_many
        class_eval %{
          def build_#{association_name}_from_nested_attributes
            self.#{association_name}.build
          end
        }
      end

      class_eval %{
        def _build_#{association_name}=( str)
          @_nested_attributes_prevent_save = true
          self._create_#{association_name}= str
        end
        attr_accessor :_build_#{association_name}_x, :_build_#{association_name}_y

        def _create_#{association_name}=( str)
          a = self.build_#{association_name}_from_nested_attributes
          a.after_build_from_nested_attributes if a.respond_to?( :after_build_from_nested_attributes)
          return a
        end
        attr_accessor :_create_#{association_name}_x, :_create_#{association_name}_y
      }
    end

    class_eval %{
      def nested_attributes_of_associations_prevent_save?
        #{association_names.inspect}.any? do |association_name|
          reflection  = self.class.reflect_on_association(association_name.to_sym)
          association = self.send( association_name)
          case reflection.macro
          when :has_one, :belongs_to
            association.nested_attributes_prevent_save? if association.respond_to?( :nested_attributes_prevent_save?)
          when :has_many, :has_and_belongs_to_many
            association.any? { |a| a.nested_attributes_prevent_save? if a.respond_to?( :nested_attributes_prevent_save?) }
          end
        end
      end

      def nested_attributes_prevent_save?
        @_nested_attributes_prevent_save || nested_attributes_of_associations_prevent_save?
      end

      before_save do |obj|
        ! obj.nested_attributes_prevent_save?
      end
    }

    return result
  end

  metaclass.alias_method_chain :accepts_nested_attributes_for, :add_association
end
