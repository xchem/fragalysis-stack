from django.http import HttpResponse
import json
from frag.network.query import get_picks,get_full_graph
from django.shortcuts import render
from network.functions import get_conn,ret_png,ret_svg


ret_type = {u'json': json.dumps, u'png': ret_png, u'svg': ret_svg}

def pick_mols(request):
    if "smiles" in request.GET \
            and "num_picks" in request.GET:
        smiles = request.GET["smiles"]
        if "num_picks" in request.GET and request.GET["num_picks"]:
            num_picks = int(request.GET["num_picks"])
        else:
            num_picks = 20
        out_dict = get_picks(smiles, num_picks)
        return HttpResponse(json.dumps(out_dict))
    else:
        return HttpResponse("Please insert SMILES")

def full_graph(request):
    if "smiles" in request.GET:
        smiles = request.GET["smiles"]
        out_dict = get_full_graph(smiles)
        return HttpResponse(json.dumps(out_dict))
    else:
        return HttpResponse("Please insert SMILES")


def query_db(request):
    if 'num_picks' in request.GET:
        limit = request.GET['num_picks']
        if not limit:
            limit = 100
    else:
        limit = 100
    if "smiles" in request.GET:
        conn = get_conn()
        curs = conn.cursor()
        curs.execute('select * from get_mfp2_neighbors(%s) limit '+str(limit),
                     (request.GET['smiles'],))
        results = curs.fetchall()
        ret_func = ret_type['json']
        if 'return' in request.GET:
            if request.GET['return'] in ret_type:
                ret_func = ret_type[request.GET['return']]
        return HttpResponse(ret_func(results))
    else:
        return HttpResponse("Please insert SMILES")

def display(request):
    return render(request, 'network/display.html', {})