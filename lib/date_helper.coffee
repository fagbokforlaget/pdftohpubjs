class DateHelper
    @toString: (date) ->
        padStr = (i) ->
            (if (i < 10) then "0" + i else "" + i)

        return padStr(date.getFullYear().toString()) + "-" +
                  padStr((1 + date.getMonth()).toString()) + "-" +
                  padStr(date.getDate().toString())

exports.DateHelper = DateHelper