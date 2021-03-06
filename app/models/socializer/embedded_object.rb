module Socializer
  class EmbeddedObject < ActiveRecord::Base
    
    attr_accessor :scope, :object_ids
    attr_accessible :scope, :object_ids
    
    belongs_to :embeddable, :polymorphic => true
    
    has_and_belongs_to_many :activities, :class_name => 'Activity', :join_table => 'socializer_audiences', :foreign_key => "object_id", :association_foreign_key => "activity_id"
    
    has_many :actor_activities,  :class_name => 'Activity', :foreign_key => 'actor_id',  :dependent => :destroy
    has_many :object_activities, :class_name => 'Activity', :foreign_key => 'object_id', :dependent => :destroy
    has_many :target_activities, :class_name => 'Activity', :foreign_key => 'target_id', :dependent => :destroy
    
    # when the embedded object is an actor (person/group)
    # it can be the owner of certain objects.
    has_many :notes,      :foreign_key => 'author_id'
    has_many :comments,   :foreign_key => 'author_id'
    has_many :groups,     :foreign_key => 'author_id'
    has_many :circles,    :foreign_key => 'author_id'
    
    has_many :ties,        :foreign_key => 'contact_id'
    has_many :memberships, :foreign_key => 'member_id', :conditions => [ "active = ?", true ]
    
    attr_accessible :like_count    
    
    def likes
      people = []
      
      activities_likes = Activity.where(:verb => 'like', :object_id => self.id)
      activities_likes.each do |activity|
        people.push activity.actor
      end
      
      activities_unlikes = Activity.where(:verb => 'unlike', :object_id => self.id)
      activities_unlikes.each do |activity|
        people.delete_at people.index(activity.actor)
      end
      
      return people
    end
    
    def like! (person)
      activity = Activity.new
      activity.actor_id = person.embedded_object.id
      activity.object_id = self.id
      activity.verb = 'like'
      activity.save!
      
      audience = Audience.new
      audience.scope = 'PUBLIC'
      audience.activity_id = activity.id
      audience.save!
      
      increment_like_count
    end
    
    def unlike! (person)
      activity = Activity.new
      activity.actor_id = person.embedded_object.id
      activity.object_id = self.id
      activity.verb = 'unlike'
      activity.save!
      
      audience = Audience.new
      audience.scope = 'PUBLIC'
      audience.activity_id = activity.id
      audience.save!
      
      decrement_like_count
    end
    
    def share!
      activity = Activity.new
      activity.actor_id = self.actor_id
      activity.object_id = self.id
      activity.verb = 'share'
      activity.save!
      
      if scope == 'PUBLIC' || scope == 'CIRCLES'
        
        audience = Audience.new
        audience.activity_id = activity.id       
        audience.scope = scope        
        audience.save!
        
      else
      
        object_ids.each do |object_id|
          audience = Audience.new
          audience.activity_id = activity.id       
          audience.scope = 'LIMITED'
          audience.object_id = object_id            
          audience.save!
        end
      
      end
      
    end
    
    def increment_like_count
      self.increment!(:like_count)
    end
    
    def decrement_like_count
      self.decrement!(:like_count)
    end
    
  end
end
