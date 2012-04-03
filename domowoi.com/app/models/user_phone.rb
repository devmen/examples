class UserPhone < ActiveRecord::Base
  belongs_to :user

  def number=(text)
    write_attribute(:number, text)
    self.clear_number = UserPhone.clear_number( text )
  end

  def self.clear_number(number)
    txt = number.to_s.gsub(/[^\d]/,'')
    txt =~ /^8(\d+)$/ ? "+7#{$1}" : "+#{txt}"
  end

	named_scope :by_clear_number, lambda{|phone| where("clear_number = ?", ClientPhone.clear_number(phone)).order("user_id")}

  def validate
    errors.add(:number, 'Номер телефона записан неверно') unless self.clear_number =~ /^\+\d{11,12}$/
    if UserPhone.exists?( ['id <> ? AND clear_number = ? and user_id <> ?', (self.id||0), self.clear_number, (self.user_id||0) ])
      errors.add(:number, 'Этот номер телефона  зарегистрирован на другого пользователя')
    end
    errors.add(:number, 'Этот номер телефона зарегистрирован на агентство') unless AgencyPhone.find_by_clear_number(self.clear_number).nil?
  end

end

