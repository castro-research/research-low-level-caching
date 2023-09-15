module ProductsHelper
    def fake_get_from_db
        response = RestClient.get 'https://swapi.dev/api/people'
        JSON.parse(response.body)
    end

    def fake_show_from_db(id)
        response = RestClient.get "https://swapi.dev/api/people/#{id}"
        JSON.parse(response.body)
    end
end
