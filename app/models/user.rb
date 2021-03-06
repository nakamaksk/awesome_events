class User < ApplicationRecord
  before_destroy :check_all_events_finished
  has_many :created_events, class_name: "Event", foreign_key: "owner_id", dependent: :nullify
  has_many :tickets, dependent: :nullify
  has_many :participating_events, through: :tickets, source: :event

  validates :email, email: true, uniqueness: true

  def self.find_or_create_from_auth_hash!(auth_hash)
    provider = auth_hash[:provider]
    uid = auth_hash[:uid]
    nickname = auth_hash[:info][:nickname]
    image_url = auth_hash[:info][:image]
    User.find_or_create_by!(provider: provider, uid: uid) do |user|
      user.name = nickname
      user.image_url = image_url
    end
  end

  # value object
  composed_of :phone_number, mapping: %w[phone_number value]

  # def phone_number
  #   @phone_number ||= PhoneNumber.new(self[:phone_number])
  # end
  #
  # def phone_number=(new_phone_number)
  #   self[:phone_number] = new_phone_number.value
  #   @phone_number = new_phone_number
  # end
  #
  private

  def check_all_events_finished
    now = Time.zone.now
    if created_events.where(":now < end_at", now: now).exists?
      errors[:base] << "公開中の未終了イベントが存在します"
    end

    if participating_events.where(":now < end_at", now: now).exists?
      errors[:base] << "未終了の参加イベントが存在します"
    end

    throw(:abort) unless errors.empty?
  end
end
