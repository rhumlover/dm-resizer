class Asset

    constructor: (options) ->
        {@name,@url,@hash} = options
        @timestamp = +new Date()

    toString: () ->
        return {
            @name
            @url
            @hash
            @timestamp
        }