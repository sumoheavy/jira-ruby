#
# Whenever a collection from a has_many relationship is accessed, an instance
# of this class is returned.  This instance wraps the Array of instances in
# the collection with an extra build method, which allows new instances to be
# built on the collection with the correct properties.
#
# In practice, instances of this class behave exactly like an Array.
#
class JIRA::Resource::HasManyProxy

  attr_reader :target_class, :parent
  attr_accessor :collection

  def initialize(parent, target_class, collection = [])
    @parent       = parent
    @target_class = target_class
    @collection   = collection
  end

  # Builds an instance of this class with the correct parent.
  # For example, issue.comments.build(attrs) will initialize a
  # comment as follows:
  #
  #   JIRA::Resource::Comment.new(issue.client,
  #                               :attrs => attrs,
  #                               :issue => issue)
  def build(attrs = {})
    target_class.new(parent.client, :attrs => attrs, parent.to_sym => parent)
  end

  # Delegate any missing methods to the collection that this proxy wraps
  def method_missing(method_name, *args, &block)
    collection.send(method_name, *args, &block)
  end
end
