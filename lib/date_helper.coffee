class DateHelper
    @toString: (date) ->
        # a helper for formating string
        # mement.js library might be used instead
        toStr = (i) ->
            (if (i < 10) then "0" + i else "" + i)

        return toStr(date.getFullYear().toString()) + "-" +
                  toStr((1 + date.getMonth()).toString()) + "-" +
                  toStr(date.getDate().toString())

exports.DateHelper = DateHelper