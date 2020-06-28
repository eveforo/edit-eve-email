# frozen_string_literal: true

# name: edit-eve-email
# about: Doesnt send confirmation email.
# version: 0.0.2
# authors: Hikryon - Iván Viguera.

register_asset "javascripts/discourse/templates/connectors/edit-eve-email-links/edit-eve-email-links.hbs"

module EditEveEmailChangeToExtension
  def change_to(email_input)
    @guardian.ensure_can_edit_email!(@user)

    email = Email.downcase(email_input.strip)
    EmailValidator.new(attributes: :email).validate_each(self, :email, email)

    if (existing_user = User.find_by_email(email))
      if SiteSetting.hide_email_address_taken
        Jobs.enqueue(:critical_user_email, type: :account_exists, user_id: existing_user.id)
      else
        error_message = +'change_email.error'
        error_message << '_staged' if existing_user.staged?
        errors.add(:base, I18n.t(error_message))
      end
    end

    if errors.blank? && existing_user.nil?
      args = {
          old_email: @user.email,
          new_email: email,
      }

      args[:change_state] = EmailChangeRequest.states[:authorizing_new]
      email_token = @user.email_tokens.create!(email: args[:new_email])
      args[:new_email_token] = email_token

      @user.email_change_requests.create!(args)

      Rails.logger.warn("EditEveEmailChangeToExtension token: #{email_token.token}")

      confirm(email_token.token)
    end
    #super(email_input)
  end
end
=begin
module UsersEmailControllerToExtension
  def update
    params.require(:email)
    user = fetch_user_from_params

    RateLimiter.new(user, "change-email-hr-#{request.remote_ip}", 6, 1.hour).performed!
    RateLimiter.new(user, "change-email-min-#{request.remote_ip}", 3, 1.minute).performed!

    updater = EmailUpdater.new(guardian, user)

    if updater.change_to(params[:email]) == :complete
      updater.user.user_stat.reset_bounce_score!
    else
      return render_json_error(updater.errors.full_messages)
    end

    redirect_url = path("/u/confirm-new-email")
    redirect_to "#{redirect_url}?done=true"

  rescue RateLimiter::LimitExceeded
    render_json_error(I18n.t("rate_limiter.slow_down"))
  end
end
=end
require_dependency 'email_updater'
class ::EmailUpdater
  prepend EditEveEmailChangeToExtension
end
