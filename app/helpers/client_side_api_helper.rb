module ClientSideApiHelper
  # Calling this method will cause the given routes to be included in the
  # rendered page for subsequent access by the client-side code. See
  # `views/layouts/javascript/_client_api_endpoints.haml` and
  # `purs/src/Utils/API.purs` for further explanation.
  # rubocop:disable Rails/HelperInstanceVariable
  def client_side_endpoints(*routes)
    @client_api_endpoints ||= {}

    routes.each do |r|
      if r.is_a? Hash
        @client_api_endpoints.merge! r
      elsif r.is_a? Symbol
        @client_api_endpoints[r] = send(r)
      else
        raise(
          "Invalid argument for client_side_endpoints: #{r.inspect} of type #{r.class.inspect}. " \
          "Must be either a symbol or a hash."
        )
      end
    end
  end
  # rubocop:enable Rails/HelperInstanceVariable
end