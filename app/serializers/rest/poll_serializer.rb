# frozen_string_literal: true

class REST::PollSerializer < ActiveModel::Serializer
  attributes :id, :expires_at, :multiple

  has_many :dynamic_options, key: :options

  def id
    object.id.to_s
  end

  def dynamic_options
    if instance_options[:include_results] && object.results_due?
      object.loaded_options
    else
      object.unloaded_options
    end
  end

  class OptionSerializer < ActiveModel::Serializer
    attributes :title, :votes
  end
end
