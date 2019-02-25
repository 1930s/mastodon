# frozen_string_literal: true
# == Schema Information
#
# Table name: polls
#
#  id          :bigint(8)        not null, primary key
#  uri         :string
#  account_id  :bigint(8)
#  status_id   :bigint(8)
#  expires_at  :datetime
#  options     :string           default([]), not null, is an Array
#  multiple    :boolean          default(FALSE), not null
#  hide_totals :boolean          default(FALSE), not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class Poll < ApplicationRecord
  belongs_to :account
  belongs_to :status, optional: true

  has_many :votes, class_name: 'PollVote', inverse_of: :poll, dependent: :destroy

  scope :attached, -> { where.not(status_id: nil) }
  scope :unattached, -> { where(status_id: nil) }

  def loaded_options
    totals = votes.group(:choice).select('choice, count(*) as total').each_with_object({}) { |item, h| h[item.choice] = item.total }
    options.map.with_index { |title, key| Option.new(self, key.to_s, title, totals[key.to_s] || 0) }
  end

  def unloaded_options
    options.map.with_index { |title, key| Option.new(self, key.to_s, title, nil) }
  end

  def expired?
    !expires_at.nil? && expires_at < Time.now.utc
  end

  def infinite?
    expires_at.nil?
  end

  def results_due?
    !hide_totals? || infinite? || expired?
  end

  class Option < ActiveModelSerializers::Model
    attributes :id, :title, :votes, :poll

    def initialize(poll, id, title, votes)
      @poll  = poll
      @id    = id
      @title = title
      @votes = votes
    end
  end
end
