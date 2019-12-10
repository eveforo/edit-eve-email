# frozen_string_literal: true

module EditEveEmailChangeTo
  def change_to(email_input)
    ## stuff
    super(email_input)
  end
end

require_dependency 'email_updater'
class ::EmailUpdater
  singleton_class.prepend EditEveEmailChangeTo
end
