require 'active_record'

module PermanentRecords
  def self.included(base)
    base.instance_eval do
      def is_permanent?
        columns.detect {|c| 'deleted_at' == c.name}
      end

      def deleted
        unscoped.where( 'deleted_at IS NOT NULL' )
      end

      def not_deleted
        unscoped.where( :deleted_at => nil )
      end

      def with_deleted
        unscoped
      end
    end

    base.send :include, InstanceMethods
  end
  
  module InstanceMethods
    def is_permanent?
      respond_to?(:deleted_at)
    end
    
    def deleted?
      deleted_at if is_permanent?
    end
    
    def set_deleted_at(value)
      return self unless is_permanent?
      record = self.class.find(id)
      record.update_attribute(:deleted_at, value)
      @attributes, @attributes_cache = record.attributes, record.attributes
    end
    
    def destroy(force = nil)
      if !is_permanent? || force == :force
        return super()
      elsif persisted? && !deleted?
        run_callbacks :destroy do 
          set_deleted_at Time.now.utc
        end
      end
      self
    end
  end
end

ActiveRecord::Base.send :include, PermanentRecords
