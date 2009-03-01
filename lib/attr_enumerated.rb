# AttrEnumerated

module AttrEnumerated # :nodoc:
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods
    def attr_enumerated(attr, *mappings)  # :nodoc:
      attr = attr.to_s if attr.is_a? Symbol
      _sym_hash   = { }
      _label_hash = { }
      _enumeration_options = [ ]
      mappings.each do |sym,val,label|
        val   ||= sym.to_s
        label ||= sym.to_s.humanize
        _sym_hash[val]    = sym
        _label_hash[val]  = label
        _enumeration_options.push [ sym,val,label ]

        val   = "'#{val}'" if val.is_a? String

        class_eval <<-EOV, __FILE__, __LINE__
          def #{sym}_#{attr}?
            self.#{attr} == #{val}
          end
          def #{sym}_#{attr}!
            self.#{attr} = #{val}
            self
          end
          def self.#{sym}_#{attr}
            #{val}
          end
          def self.#{sym}_#{attr}_label
            '#{label}'
          end
        EOV
      end

      write_inheritable_attribute("#{attr}_sym_hash".to_sym,   _sym_hash)
      write_inheritable_attribute("#{attr}_label_hash".to_sym, _label_hash)
      write_inheritable_attribute("#{attr}_enumeration_options".to_sym, _enumeration_options)

      class_eval <<-EOV, __FILE__, __LINE__
        def self.#{attr}_symbols
          ( read_inheritable_attribute(:#{attr}_sym_hash) || { } )
        end
        def self.#{attr}_labels
          ( read_inheritable_attribute(:#{attr}_label_hash) || { } )
        end
        def self.#{attr.to_s.pluralize}_for_select
          ( read_inheritable_attribute(:#{attr}_label_hash) || { } ).sort { |a,b| a[1] <=> b[1] }.collect { |value,label| [ label, value ] }
        end
        def self.#{attr}_enumeration_options
          ( read_inheritable_attribute(:#{attr}_enumeration_options) || { } )
        end
        def #{attr}_label
          ( #{self}.read_inheritable_attribute(:#{attr}_label_hash) || { } )[self.#{attr}]
        end
        def #{attr}_symbol
          ( #{self}.read_inheritable_attribute(:#{attr}_sym_hash) || { } )[self.#{attr}]
        end
        def valid_#{attr}?
          ( #{self}.read_inheritable_attribute(:#{attr}_sym_hash) || { }).has_key?(self.#{attr})
        end
        def self.valid_#{attr}?(value)
          (read_inheritable_attribute(:#{attr}_sym_hash) || { }).has_key?(value)
        end
        def self.validates_#{attr}(opts = {})
          configuration = { :message => I18n.translate('activerecord.errors.messages[:inclusion]'), :on => :save }.merge(opts)
          validates_each(:#{attr}, configuration) do |record, attr_name, value|
            record.errors.add(attr_name, configuration[:message] % value) unless self.valid_#{attr}?(value)
          end
        end
      EOV
    end # attr_enumerated
  end # ClassMethods
end # AttrEnumerated

ActiveRecord::Base.class_eval do
  include AttrEnumerated
end
