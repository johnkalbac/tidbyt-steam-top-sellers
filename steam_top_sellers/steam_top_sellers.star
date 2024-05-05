load("render.star", "render")
load("http.star", "http")
load("animation.star", "animation")
load("random.star", "random")

global_http_ttl_seconds = 60
global_result_limit = 1 # Limit results to minimize rendered file size

def main(config):
    top_sellers = get_top_sellers()
    frames = build_frames(top_sellers)

    return render.Root(
        render.Sequence(frames),
        show_full_animation=True,
        delay=90
    )

def get_top_sellers():
    # Fetch the featured games from the Steam API
    url = "https://store.steampowered.com/api/featuredcategories"
    response = http.get(
        url, 
        ttl_seconds = global_http_ttl_seconds
    )
    if response.status_code != 200:
        fail("GET %s failed with status %d: %s" % (url, response.status_code, response.body()))
    
    raw_data = response.json()
    #print("raw_data: %s" % (raw_data))
    top_sellers = raw_data['top_sellers']['items']
    #print("top_sellers: %s" % (top_sellers))
    return top_sellers

def build_frames(top_sellers):
    # Iterate top_sellers list and extract details
    frames = []
    counter = 0
    # Shuffle the results
    top_sellers_sorted = sorted(top_sellers, key=lambda x: random.number(0, 100))
    for item in top_sellers_sorted:
        name = item['name']

        # Omit Steam Deck entries
        if name != "Steam Deck" and counter < global_result_limit:
            print("name: %s, counter: %s" % (name, str(counter)))
            discount_percent = item['discount_percent']
            final_price_formatted = format_price(
                item['final_price'],
                item['currency'],
                item['discount_percent']
            )
            image = fetch_image(item['small_capsule_image'])

            # Add Details
            frames.append(get_details_widget(name, final_price_formatted, discount_percent))

            # Add Image
            frames.append(get_image_widget(image))

            counter = counter + 1
    
    return frames

def get_details_widget(name, final_price_formatted, discount_percent):
    return render.Stack(
            children = [
                
                # Header section
                render.Column(
                    main_align = "start",
                    expanded = True,
                    children = [
                        render.Row(
                            main_align = "center",
                            expanded = True,
                            children = [
                                render.Text("Steam", color = "#132b8a", font="5x8"),
                            ],
                        ),
                    ],
                ),

                # Floating middle section for name marquee 
                render.Column(
                    main_align = "center",
                    expanded = True,
                    children = [
                        render.Row(
                            main_align = "space_around",
                            expanded = True,
                            children = [
                                render.Box(
                                    color = "#132b8a",
                                    height = 15,
                                    child = render.Marquee(
                                        height=10,
                                        width=60,
                                        #delay=10,
                                        child=render.Text(name, color="#ffff"),
                                        offset_start=0,
                                        offset_end=32,
                                        align="center"
                                    ),
                                )
                            ],
                        ),
                    ],
                ),
                # Lower section for price and (optional) discount percentage
                render.Column(
                    main_align = "end",  # bottom
                    expanded = True,
                    children = [
                        render.Row(
                            main_align = "space_evenly",
                            expanded = True,
                            children = [
                                render.Text(final_price_formatted, color="#132b8a", font="5x8"),
                                render.Text(get_discount(discount_percent), color="#05a81e", font="5x8")
                            ],
                        ),
                    ],
                ),
            ]
        )

def get_image_widget(image):
    return animation.Transformation(
                child = render.Image(
                    src = image,
                    width = 184,
                    height = 69,
                ),
                duration = 10,
                delay = 0,
                origin = animation.Origin(0.0, 0.2),
                direction = "alternate",
                fill_mode = "forwards",
                keyframes = [
                    animation.Keyframe(
                        percentage = 0.0,
                        transforms = [animation.Scale(.5, .5), animation.Translate(-60, -20)],
                        #curve = "ease_in_out",
                    ),
                ],
            )

def fetch_image(image_url):
    print("    image: %s" % (image_url))
    response = http.get(
        image_url, 
        ttl_seconds = global_http_ttl_seconds
    )
    if response.status_code != 200:
        fail("GET %s failed with status %d: %s" % (image_url, response.status_code, response.body()))
    
    return response.body()

def format_price(amount, currency, discount_percent):
    amount_str = str(amount)
    
    # Crude formatting; why isn't this a native convenience function?
    if (amount == 0):
        fomatted_amount = "$0"
    elif len(amount_str) <= 3:
        fomatted_amount = "$" + amount_str
    else:
        formatted_amount = ('$' + amount_str[:-4] + '.' + amount_str[-4:-2])

    #formatted_amount += ' ' + currency
    print("    price: %s" % (formatted_amount))
    return formatted_amount

def get_discount(discount_percent):
    if discount_percent > 0:
        return "-%s" % str(discount_percent)[:-2] + "%"
    else:
        return ''